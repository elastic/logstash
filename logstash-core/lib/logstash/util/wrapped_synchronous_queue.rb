# encoding: utf-8

module LogStash; module Util
  class WrappedSynchronousQueue
    java_import java.util.concurrent.ArrayBlockingQueue
    java_import java.util.concurrent.TimeUnit
    java_import java.util.HashSet
    java_import org.logstash.common.LsQueueUtils

    def initialize (size)
      @queue = ArrayBlockingQueue.new(size)
    end

    attr_reader :queue

    # Push an object to the queue if the queue is full
    # it will block until the object can be added to the queue.
    #
    # @param [obj] Object to add to the queue
    def push(obj)
      @queue.put(obj)
    end
    alias_method(:<<, :push)

    # Block for X millis
    def poll(millis)
      @queue.poll(millis, TimeUnit::MILLISECONDS)
    end

    def write_client
      WriteClient.new(self)
    end

    def read_client
      ReadClient.new(self)
    end

    def close
      # ignore
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
        @wait_for = TimeUnit::NANOSECONDS.convert(wait_for, TimeUnit::MILLISECONDS)
      end

      def close
        # noop, compat with acked queue read client
      end

      def empty?
        @queue.queue.isEmpty
      end

      def set_batch_dimensions(batch_size, wait_for)
        @batch_size = batch_size
        @wait_for = TimeUnit::NANOSECONDS.convert(wait_for, TimeUnit::MILLISECONDS)
      end

      def set_events_metric(metric)
        @event_metric = metric
        @event_metric_out = @event_metric.counter(:out)
        @event_metric_filtered = @event_metric.counter(:filtered)
        @event_metric_time = @event_metric.counter(:duration_in_millis)
        define_initial_metrics_values(@event_metric)
      end

      def set_pipeline_metric(metric)
        @pipeline_metric = metric
        @pipeline_metric_out = @pipeline_metric.counter(:out)
        @pipeline_metric_filtered = @pipeline_metric.counter(:filtered)
        @pipeline_metric_time = @pipeline_metric.counter(:duration_in_millis)
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

      def current_inflight_batch
        @inflight_batches.fetch(Thread.current, [])
      end

      # create a new empty batch
      # @return [ReadBatch] a new empty read batch
      def new_batch
        ReadBatch.new(@queue, 0, 0)
      end

      def read_batch
        batch = ReadBatch.new(@queue, @batch_size, @wait_for)
        start_metrics(batch)
        batch
      end

      def start_metrics(batch)
        @mutex.lock
        # there seems to be concurrency issues with metrics, keep it in the mutex
        begin
          set_current_thread_inflight_batch(batch)
          start_clock
        ensure
          @mutex.unlock
        end
      end

      def set_current_thread_inflight_batch(batch)
        @inflight_batches[Thread.current] = batch
      end

      def close_batch(batch)
        @mutex.lock
        begin
          # there seems to be concurrency issues with metrics, keep it in the mutex
          @inflight_batches.delete(Thread.current)
          stop_clock(batch)
        ensure
          @mutex.unlock
        end
      end

      def start_clock
        @inflight_clocks[Thread.current] = java.lang.System.nano_time
      end

      def stop_clock(batch)
        unless @inflight_clocks[Thread.current].nil?
          if batch.size > 0
            # only stop (which also records) the metrics if the batch is non-empty.
            # start_clock is now called at empty batch creation and an empty batch could
            # stay empty all the way down to the close_batch call.
            time_taken = (java.lang.System.nano_time - @inflight_clocks[Thread.current]) / 1_000_000
            @event_metric_time.increment(time_taken)
            @pipeline_metric_time.increment(time_taken)
          end
          @inflight_clocks.delete(Thread.current)
        end
      end

      def add_filtered_metrics(batch)
        @event_metric_filtered.increment(batch.filtered_size)
        @pipeline_metric_filtered.increment(batch.filtered_size)
      end

      def add_output_metrics(batch)
        @event_metric_out.increment(batch.filtered_size)
        @pipeline_metric_out.increment(batch.filtered_size)
      end
    end

    class ReadBatch
      def initialize(queue, size, wait)
        @queue = queue.queue
        @size = size
        @wait = wait

        # TODO: disabled for https://github.com/elastic/logstash/issues/6055 - will have to properly refactor
        # @cancelled = Hash.new

        #Sizing HashSet to size/load_factor to ensure no rehashing
        @is_iterating = false # Atomic Boolean maybe? Although batches are not shared across threads
        @acked_batch = nil
        @originals = LsQueueUtils.drain(@queue, @size, @wait)
      end

      def merge(event)
        return if event.nil? || @originals.contains(event)
        # take care not to cause @generated to change during iteration
        # @iterating_temp is merged after the iteration
        if @is_iterating
          @iterating_temp = HashSet.new if @iterating_temp.nil?
          @iterating_temp.add(event)
        else
          # the periodic flush could generate events outside of an each iteration
          @originals.add(event)
        end
      end

      def cancel(event)
        # TODO: disabled for https://github.com/elastic/logstash/issues/6055 - will have to properly refactor
        raise("cancel is unsupported")
        # @cancelled[event] = true
      end

      def each(&blk)
        # take care not to cause @originals or @generated to change during iteration
        @is_iterating = true

        # below the checks for @cancelled.include?(e) have been replaced by e.cancelled?
        # TODO: for https://github.com/elastic/logstash/issues/6055 = will have to properly refactor
        @originals.each do |e|
          blk.call(e) unless e.cancelled?
        end
        @is_iterating = false
        update_generated unless @iterating_temp.nil?
      end

      def filtered_size
        @originals.size
      end

      alias_method(:size, :filtered_size)

      def cancelled_size
      # TODO: disabled for https://github.com/elastic/logstash/issues/6055 = will have to properly refactor
      raise("cancelled_size is unsupported ")
        # @cancelled.size
      end

      private

      def update_generated
        @originals.add_all(@iterating_temp)
        # Iterating Temp will not be used again in the lifecycle of the batch so we
        # give a hint to the garbage collector here
        @iterating_temp = nil
      end
    end

    class WriteClient
      def initialize(queue)
        @queue = queue.queue
      end

      def get_new_batch
        []
      end

      def push(event)
        @queue.put(event)
      end
      alias_method(:<<, :push)

      def push_batch(batch)
        LsQueueUtils.addAll(@queue, batch)
      end
    end
  end
end end
