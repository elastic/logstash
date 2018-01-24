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
      @closed = java.util.concurrent.atomic.AtomicBoolean.new(false)
      self
    end

    def closed?
      @closed.get
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

    def read_batch(size, wait)
      check_closed("read a batch")
      @queue.read_batch(size, wait)
    end

    def write_client
      LogStash::AckedWriteClient.create(@queue, @closed)
    end

    def read_client()
      ReadClient.new(self)
    end

    def check_closed(action)
      if @closed.get
        raise QueueClosedError.new("Attempted to #{action} on a closed AckedQueue")
      end
    end

    def is_empty?
      @queue.is_empty?
    end

    def close
      @queue.close
      @closed.set(true)
    end

    class ReadClient
      # We generally only want one thread at a time able to access pop/take/poll operations
      # from this queue. We also depend on this to be able to block consumers while we snapshot
      # in-flight buffers

      def initialize(queue, batch_size = 125, wait_for = 50)
        @queue = queue
        # Note that @inflight_batches as a central mechanism for tracking inflight
        # batches will fail if we have multiple read clients in the pipeline.
        @inflight_batches = Concurrent::Map.new
        # allow the worker thread to report the execution time of the filter + output
        @inflight_clocks = Concurrent::Map.new
        @batch_size = batch_size
        @wait_for = wait_for
      end

      def close
        @queue.close
      end

      def empty?
        @queue.is_empty?
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
        @inflight_batches
      end

      # create a new empty batch
      # @return [ReadBatch] a new empty read batch
      def new_batch
        LogStash::AckedReadBatch.new(@queue, 0, 0)
      end

      def read_batch
        if @queue.closed?
          raise QueueClosedError.new("Attempt to take a batch from a closed AckedQueue")
        end

        batch = LogStash::AckedReadBatch.new(@queue, @batch_size, @wait_for)
        start_metrics(batch)
        batch
      end

      def start_metrics(batch)
        thread = Thread.current
        @inflight_batches[thread] = batch
        @inflight_clocks[thread] = java.lang.System.nano_time
      end

      def close_batch(batch)
        thread = Thread.current
        batch.close
        @inflight_batches.delete(thread)
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
  end
end end
