# encoding: utf-8

require "concurrent"
# This is an adapted copy of the wrapped_synchronous_queue file
# ideally this should be moved to Java/JRuby

module LogStash; module Util
  # Some specialized constructors. The calling code *does* need to know what kind it creates but
  # not the internal implementation e.g. LogStash::AckedMemoryQueue etc.
  # Note the use of allocate - this is what new does before it calls initialize.
  # Note that the new method has been made private this is because there is no
  # default queue implementation.
  # It would be expensive to create a persistent queue in the new method
  # to then throw it away in favor of a memory based one directly after.
  # Especially in terms of (mmap) memory allocation and proper close sequencing.

  class WrappedAckedQueue
    class QueueClosedError < ::StandardError; end
    class NotImplementedError < ::StandardError; end

    def self.create_memory_based(path, capacity, max_events, max_bytes)
      self.allocate.with_queue(
        LogStash::AckedMemoryQueue.new(path, capacity, max_events, max_bytes)
      )
    end

    def self.create_file_based(path, capacity, max_events, checkpoint_max_writes, checkpoint_max_acks, checkpoint_max_interval, max_bytes)
      self.allocate.with_queue(
        LogStash::AckedQueue.new(path, capacity, max_events, checkpoint_max_writes, checkpoint_max_acks, checkpoint_max_interval, max_bytes)
      )
    end

    private_class_method :new

    attr_reader :queue

    def with_queue(queue)
      @queue = queue
      @queue.open
      @closed = Concurrent::AtomicBoolean.new(false)
      self
    end

    def closed?
      @closed.true?
    end

    # Push an object to the queue if the queue is full
    # it will block until the object can be added to the queue.
    #
    # @param [Object] Object to add to the queue
    def push(obj)
      check_closed("write")
      @queue.write(obj)
    end
    alias_method(:<<, :push)

    # Block for X millis
    def poll(millis)
      check_closed("read")
      @queue.read_batch(1, millis).get_elements.first
    end

    def read_batch(size, wait)
      check_closed("read a batch")
      @queue.read_batch(size, wait)
    end

    def write_client
      WriteClient.new(self)
    end

    def read_client()
      ReadClient.new(self)
    end

    def check_closed(action)
      if closed?
        raise QueueClosedError.new("Attempted to #{action} on a closed AckedQueue")
      end
    end

    def is_empty?
      @queue.is_empty?
    end

    def close
      @queue.close
      @closed.make_true
    end

    class ReadClient
      # We generally only want one thread at a time able to access pop/take/poll operations
      # from this queue. We also depend on this to be able to block consumers while we snapshot
      # in-flight buffers

      def initialize(queue, batch_size = 125, wait_for = 50)
        @queue = queue
        @mutex = Mutex.new
        # Note that @inflight_batches as a central mechanism for tracking inflight
        # batches will fail if we have multiple read clients in the pipeline.
        @inflight_batches = {}
        # allow the worker thread to report the execution time of the filter + output
        @inflight_clocks = Concurrent::Map.new
        @batch_size = batch_size
        @wait_for = wait_for
      end

      def close
        @queue.close
      end

      def empty?
        @mutex.lock
        begin
          @queue.is_empty?
        ensure
          @mutex.unlock
        end
      end

      def set_batch_dimensions(batch_size, wait_for)
        @batch_size = batch_size
        @wait_for = wait_for
      end

      def set_events_metric(metric)
        @event_metric = metric
        define_initial_metrics_values(@event_metric)
      end

      def set_pipeline_metric(metric)
        @pipeline_metric = metric
        define_initial_metrics_values(@pipeline_metric)
      end

      def define_initial_metrics_values(namespaced_metric)
        namespaced_metric.report_time(:duration_in_millis, 0)
        namespaced_metric.increment(:filtered, 0)
        namespaced_metric.increment(:out, 0)
      end

      def inflight_batches
        @mutex.lock
        begin
          yield(@inflight_batches)
        ensure
          @mutex.unlock
        end
      end

      # create a new empty batch
      # @return [ReadBatch] a new empty read batch
      def new_batch
        ReadBatch.new(@queue, @batch_size, @wait_for)
      end

      def read_batch
        if @queue.closed?
          raise QueueClosedError.new("Attempt to take a batch from a closed AckedQueue")
        end

        batch = new_batch
        batch.read_next
        start_metrics(batch)
        batch
      end

      def start_metrics(batch)
        thread = Thread.current
        @mutex.lock
        begin
          @inflight_batches[thread] = batch
        ensure
          @mutex.unlock
        end
        @inflight_clocks[thread] = java.lang.System.nano_time
      end

      def close_batch(batch)
        thread = Thread.current
        @mutex.lock
        begin
          batch.close
          @inflight_batches.delete(thread)
        ensure
          @mutex.unlock
        end
        start_time = @inflight_clocks.get_and_set(thread, nil)
        unless start_time.nil?
          if batch.size > 0
            # only stop (which also records) the metrics if the batch is non-empty.
            # start_clock is now called at empty batch creation and an empty batch could
            # stay empty all the way down to the close_batch call.
            time_taken = (java.lang.System.nano_time - start_time) / 1_000_000
            @event_metric.report_time(:duration_in_millis, time_taken)
            @pipeline_metric.report_time(:duration_in_millis, time_taken)
          end
        end
      end

      def add_filtered_metrics(filtered_size)
        @event_metric.increment(:filtered, filtered_size)
        @pipeline_metric.increment(:filtered, filtered_size)
      end

      def add_output_metrics(filtered_size)
        @event_metric.increment(:out, filtered_size)
        @pipeline_metric.increment(:out, filtered_size)
      end
    end

    class ReadBatch
      def initialize(queue, size, wait)
        @queue = queue
        @size = size
        @wait = wait

        @originals = Hash.new

        # TODO: disabled for https://github.com/elastic/logstash/issues/6055 - will have to properly refactor
        # @cancelled = Hash.new

        @generated = Hash.new
        @acked_batch = nil
      end

      def read_next
        @acked_batch = @queue.read_batch(@size, @wait)
        return if @acked_batch.nil?
        @acked_batch.get_elements.each { |e| @originals[e] = true }
      end

      def close
        # this will ack the whole batch, regardless of whether some
        # events were cancelled or failed
        return if @acked_batch.nil?
        @acked_batch.close
      end

      def merge(event)
        return if event.nil? || @originals.key?(event)
        @generated[event] = true
      end

      def to_a
        events = []
        each {|e| events << e}
        events
      end

      def each(&blk)
        # below the checks for @cancelled.include?(e) have been replaced by e.cancelled?
        # TODO: for https://github.com/elastic/logstash/issues/6055 = will have to properly refactor
        @originals.each do |e, _|
          blk.call(e) unless e.cancelled?
        end
        @generated.each do |e, _|
          blk.call(e) unless e.cancelled?
        end
      end

      def size
        filtered_size
      end

      def starting_size
        @originals.size
      end

      def filtered_size
        @originals.size + @generated.size
      end

      def shutdown_signal_received?
        false
      end

      def flush_signal_received?
        false
      end
    end

    class WriteClient
      def initialize(queue)
        @queue = queue
      end

      def push(event)
        if @queue.closed?
          raise QueueClosedError.new("Attempted to write an event to a closed AckedQueue")
        end
        @queue.push(event)
      end
      alias_method(:<<, :push)

      def push_batch(batch)
        if @queue.closed?
          raise QueueClosedError.new("Attempted to write a batch to a closed AckedQueue")
        end
        batch.each do |event|
          push(event)
        end
      end
    end
  end
end end
