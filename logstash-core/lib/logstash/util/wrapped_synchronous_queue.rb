# encoding: utf-8

module LogStash; module Util
  class WrappedSynchronousQueue
    java_import java.util.concurrent.SynchronousQueue
    java_import java.util.concurrent.TimeUnit

    attr_reader :read_file_pool, :write_file_pool

    def initialize
      @queue = java.util.concurrent.SynchronousQueue.new

      # This should really be the number of workers, but I just set it here to a high number
      # out of laziness
      num_files = 20

      @write_file_pool = java.util.concurrent.ArrayBlockingQueue.new(num_files)
      @read_file_pool = java.util.concurrent.ArrayBlockingQueue.new(num_files+200)

      num_files.times do |t|
        @write_file_pool.put(::File.open("/tmp/lsq/#{t}.batch", "a+"))
      end

      @writer_thread = Thread.new do |t|
        @current_file = @write_file_pool.take()
        count = 0

        while true
          event_or_signal = @queue.poll(50, TimeUnit::MILLISECONDS)
          next if event_or_signal.nil?

          break if event_or_signal == :shutdown

          if count >= 512 || event_or_signal == :steal
            next if count < 1 # You can't steal nothin'!
            @current_file.fsync
            @read_file_pool.put(@current_file)
            @current_file = @write_file_pool.take()
            count = 0
          end

          if event_or_signal.is_a?(::LogStash::Event)
            count += 1
            @current_file.write(event_or_signal.to_json)
            @current_file.write("\n")
          end
        end
      end
    end

    # Push an object to the queue if the queue is full
    # it will block until the object can be added to the queue.
    #
    # @param [Object] Object to add to the queue
    def push(obj)
      @queue.put(obj)
    end
    alias_method(:<<, :push)

    # Offer an object to the queue, wait for the specified amount of time.
    # If adding to the queue was successful it wil return true, false otherwise.
    #
    # @param [Object] Object to add to the queue
    # @param [Integer] Time in milliseconds to wait before giving up
    # @return [Boolean] True if adding was successful if not it return false
    def offer(obj, timeout_ms)
      @queue.offer(obj, timeout_ms, TimeUnit::MILLISECONDS)
    end

    # Blocking
    def take
      @queue.take
    end

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
      @queue.put :shutdown
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

        @read_file_pool = queue.read_file_pool
      end

      def close
        @read_file_pool.put(:shutdown)
      end

      def empty?
        true # synchronous queue is alway empty
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

      def current_inflight_batch
        @inflight_batches.fetch(Thread.current, [])
      end

      # create a new empty batch
      # @return [ReadBatch] a new empty read batch
      def new_batch
        ReadBatch.new(@queue, @batch_size, @wait_for)
      end

      def read_batch
        batch = new_batch
        @mutex.lock
        begin
          batch.read_next
        ensure
          @mutex.unlock
        end
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
        batch.close
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
        @inflight_clocks[Thread.current] = [
          @event_metric.time(:duration_in_millis),
          @pipeline_metric.time(:duration_in_millis)
        ]
      end

      def stop_clock(batch)
        unless @inflight_clocks[Thread.current].nil?
          if batch.size > 0
            # only stop (which also records) the metrics if the batch is non-empty.
            # start_clock is now called at empty batch creation and an empty batch could
            # stay empty all the way down to the close_batch call.
            @inflight_clocks[Thread.current].each(&:stop)
          end
          @inflight_clocks.delete(Thread.current)
        end
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
      attr_reader :file

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
        @file = @queue.read_file_pool.poll(5, TimeUnit::MILLISECONDS)
        break if file == :shutdown
        if file.nil?
          @queue.push(:steal)
          return
        end

        return if @file == :shutdown
        @file.rewind
        @file.each_line do |line|
          event = Event.from_json(line).first
          @originals[event] = true
        end
      end

      def close
        if @file
          @file.truncate(0)
          @queue.write_file_pool.put(file);
        end
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
        @iterating = true

        # below the checks for @cancelled.include?(e) have been replaced by e.cancelled?
        # TODO: for https://github.com/elastic/logstash/issues/6055 = will have to properly refactor
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
