# encoding: utf-8

module LogStash; module Util
  class WrappedSynchronousQueue
    java_import java.util.concurrent.SynchronousQueue
    java_import java.util.concurrent.TimeUnit

    def initialize()
      @queue = java.util.concurrent.SynchronousQueue.new()
    end

    # Push an object to the queue if the queue is full
    # it will block until the object can be added to the queue.
    #
    # @param [Object] Object to add to the queue
    def push(obj)
      @queue.put(obj)
    end
    alias_method(:<<, :push)

    # Offer an object to the queue, wait for the specified amout of time.
    # If adding to the queue was successfull it wil return true, false otherwise.
    #
    # @param [Object] Object to add to the queue
    # @param [Integer] Time in milliseconds to wait before giving up
    # @return [Boolean] True if adding was successfull if not it return false
    def offer(obj, timeout_ms)
      @queue.offer(obj, timeout_ms, TimeUnit::MILLISECONDS)
    end

    # Blocking
    def take
      @queue.take()
    end

    # Block for X millis
    def poll(millis)
      @queue.poll(millis, TimeUnit::MILLISECONDS)
    end

    def write_client
      WriteClient.new(self)
    end

    def read_client()
      ReadClient.new(self)
    end

    class ReadClient
      # We generally only want one thread at a time able to access pop/take/poll operations
      # from this queue. We also depend on this to be able to block consumers while we snapshot
      # in-flight buffers

      def initialize(queue, batch_size = 125, wait_for = 5)
        @queue = queue
        @mutex = Mutex.new
        # Note that @infilght_batches as a central mechanism for tracking inflight
        # batches will fail if we have multiple read clients in the pipeline.
        @inflight_batches = {}
        @batch_size = batch_size
        @wait_for = wait_for
      end

      def set_batch_dimensions(batch_size, wait_for)
        @batch_size = batch_size
        @wait_for = wait_for
      end

      def set_events_metric(metric)
        @event_metric = metric
      end

      def set_pipeline_metric(metric)
        @pipeline_metric = metric
      end

      def inflight_batches
        @mutex.synchronize do
          yield(@inflight_batches)
        end
      end

      def current_inflight_batch
        @inflight_batches.fetch(Thread.current, [])
      end

      def take_batch
        @mutex.synchronize do
          # guaranteed to be a full batch not a partial batch
          signal = false
          batch = ReadBatch.new(@queue, @batch_size, @wait_for)
          add_starting_metrics(batch)
          set_current_thread_inflight_batch(batch)
          batch
        end
      end

      def set_current_thread_inflight_batch(batch)
        @inflight_batches[Thread.current] = batch
      end

      def close_batch(batch)
        @mutex.synchronize do
          @inflight_batches.delete(Thread.current)
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
        @shutdown_signal_received = false
        @flush_signal_received = false
        @originals = Hash.new
        @cancelled = []
        @failed = []
        @generated = Hash.new
        size.times do |t|
          event = (t == 0) ? queue.take : queue.poll(wait)
          if event.nil?
            # queue poll timed out
            next
          elsif event == LogStash::SHUTDOWN
            # We MUST break here. If a batch consumes two SHUTDOWN events
            # then another worker may have its SHUTDOWN 'stolen', thus blocking
            # the pipeline.
            @shutdown_signal_received = true
            break
          elsif event == LogStash::FLUSH
            # See comment above
            # We should stop doing work after flush as well.
            @flush_signal_received = true
            break
          else
            @originals[event] = true
          end
        end
      end

      def merge(event)
        return if event.nil? || @originals.include?(event)
        @generated[event] = true
      end

      def cancel(event)
        @originals.delete(event)
        @generated.delete(event)
        @cancelled.push(event)
      end

      def each(&blk)
        active_events.each do |e|
          blk.call(e)
        end
      end

      def size
        active_events.size
      end

      def starting_size
        @originals.size
      end

      def filtered_size
        starting_size + @generated.size
      end

      def cancelled_size
        @cancelled.size
      end

      def failed_size
        @failed.size
      end

      def shutdown_signal_received?
        @shutdown_signal_received
      end

      def flush_signal_received?
        @flush_signal_received
      end

      private

      def active_events
        # returns a snapshot of the contents of
        # both sets of events.
        @originals.keys + @generated.keys
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
        @queue.push(event)
      end
      alias_method(:<<, :push)

      def push_batch(batch)
        batch.each do |event|
          push(event)
        end
      end
    end

    class WriteBatch
      def initialize
        @events = []
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
