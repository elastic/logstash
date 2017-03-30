# encoding: utf-8

require "jruby_acked_queue_ext"
require "jruby_acked_batch_ext"
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

    # TODO - fix doc for this noop method
    # Offer an object to the queue, wait for the specified amount of time.
    # If adding to the queue was successful it will return true, false otherwise.
    #
    # @param [Object] Object to add to the queue
    # @param [Integer] Time in milliseconds to wait before giving up
    # @return [Boolean] True if adding was successful if not it return false
    def offer(obj, timeout_ms)
      raise NotImplementedError.new("The offer method is not implemented. There is no non blocking write operation yet.")
    end

    # Blocking
    def take
      check_closed("read a batch")
      # TODO - determine better arbitrary timeout millis
      @queue.read_batch(1, 200).get_elements.first
    end

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

    def close
      @queue.close
      @closed.make_true
    end

    class ReadClient
      # We generally only want one thread at a time able to access pop/take/poll operations
      # from this queue. We also depend on this to be able to block consumers while we snapshot
      # in-flight buffers

      def initialize(queue, batch_size = 125, wait_for = 250)
        @queue = queue
        @mutex = Mutex.new
        # Note that @inflight_batches as a central mechanism for tracking inflight
        # batches will fail if we have multiple read clients in the pipeline.
        @inflight_batches = {}
        # allow the worker thread to report the execution time of the filter + output
        @inflight_clocks = {}
        @batch_size = batch_size
        @wait_for = wait_for
      end

      def close
        @queue.close
      end

      def empty?
        @mutex.synchronize { @queue.is_fully_acked? }
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
        @mutex.synchronize do
          yield(@inflight_batches)
        end
      end

      def current_inflight_batch
        @inflight_batches.fetch(Thread.current, [])
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
        @mutex.synchronize { batch.read_next }
        start_metrics(batch)
        batch
      end

      def start_metrics(batch)
        @mutex.synchronize do
          # there seems to be concurrency issues with metrics, keep it in the mutex
          set_current_thread_inflight_batch(batch)
          start_clock
        end
      end

      def set_current_thread_inflight_batch(batch)
        @inflight_batches[Thread.current] = batch
      end

      def close_batch(batch)
        @mutex.synchronize do
          batch.close

          # there seems to be concurrency issues with metrics, keep it in the mutex
          @inflight_batches.delete(Thread.current)
          stop_clock(batch)
        end
      end

      def start_clock
        @inflight_clocks[Thread.current] = [
          @event_metric.time(:duration_in_millis),
          @pipeline_metric.time(:duration_in_millis)
        ]
      end

      def stop_clock(batch)
        unless @inflight_clocks[Thread.current].nil?
          if batch.size > 0
            # onl/y stop (which also records) the metrics if the batch is non-empty.
            # start_clock is now called at empty batch creation and an empty batch could
            # stay empty all the way down to the close_batch call.
            @inflight_clocks[Thread.current].each(&:stop)
          end
          @inflight_clocks.delete(Thread.current)
        end
      end

      def add_starting_metrics(batch)
        return if @event_metric.nil? || @pipeline_metric.nil?
        @event_metric.increment(:in, batch.starting_size)
        @pipeline_metric.increment(:in, batch.starting_size)
      end

      def add_filtered_metrics(batch)
        @event_metric.increment(:filtered, batch.filtered_size)
        @pipeline_metric.increment(:filtered, batch.filtered_size)
      end

      def add_output_metrics(batch)
        @event_metric.increment(:out, batch.filtered_size)
        @pipeline_metric.increment(:out, batch.filtered_size)
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
        @iterating_temp = Hash.new
        @iterating = false # Atomic Boolean maybe? Although batches are not shared across threads
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
        # take care not to cause @generated to change during iteration
        # @iterating_temp is merged after the iteration
        if iterating?
          @iterating_temp[event] = true
        else
          # the periodic flush could generate events outside of an each iteration
          @generated[event] = true
        end
      end

      def cancel(event)
        # TODO: disabled for https://github.com/elastic/logstash/issues/6055 - will have to properly refactor
        raise("cancel is unsupported")
        # @cancelled[event] = true
      end

      def each(&blk)
        # take care not to cause @originals or @generated to change during iteration

        # below the checks for @cancelled.include?(e) have been replaced by e.cancelled?
        # TODO: for https://github.com/elastic/logstash/issues/6055 = will have to properly refactor
        @iterating = true
        @originals.each do |e, _|
          blk.call(e) unless e.cancelled?
        end
        @generated.each do |e, _|
          blk.call(e) unless e.cancelled?
        end
        @iterating = false
        update_generated
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

      def cancelled_size
        # TODO: disabled for https://github.com/elastic/logstash/issues/6055 = will have to properly refactor
        raise("cancelled_size is unsupported ")
        # @cancelled.size
      end

      def shutdown_signal_received?
        false
      end

      def flush_signal_received?
        false
      end

      private

      def iterating?
        @iterating
      end

      def update_generated
        @generated.update(@iterating_temp)
        @iterating_temp.clear
      end
    end

    class WriteClient
      def initialize(queue)
        @queue = queue
      end

      def get_new_batch
        WriteBatch.new
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

    class WriteBatch
      def initialize
        @events = []
      end

      def size
        @events.size
      end

      def push(event)
        @events.push(event)
      end
      alias_method(:<<, :push)

      def each(&blk)
        @events.each do |e|
          blk.call(e)
        end
      end
    end
  end
end end
