# encoding: utf-8
require "logstash/instrument/concurrent_linked_queue"
# require "concurrent/timer/task"
require "cabin"

module LogStash module Instrument
  module Logger

    @logger = Cabin::Channel.get(LogStash)
    def self.logger=(new_logger)
      @logger = new_logger
    end

    def self.logger
      @logger
    end
  end

  class Bucket
    attr_reader :metrics

    def initialize
      # This will be called by multiples threads
      # and need to be thread safe
      @metrics = ConcurrentLinkedQueue.new
    end

    def push(metric)
      @metrics.offer(metric)
    end

    # When we summarize we could still be writting in the object
    def summarize
      # implement
    end
  end


  class Collector
    include Logger
    DEFAULT_BUCKET_RESOLUTION = 1 # in seconds

    attr_reader :buckets

    def initialize(options = {})
      @buckets = []
      @bucket_lock = Mutex.new
      @bucket_resolution = options.fetch(:bucket_window, DEFAULT_BUCKET_RESOLUTION)
      @last_bucket_rollover = Time.now
      buckets << Bucket.new
    end

    # This part of the code is called from multiple thread
    def push(type, time, value)
      # bucket.push([type, time, keys, value])
    end

    def bucket
      # Fair thread rollover of the bucket
      # Only one thread should can change the content of the buckets
      # Can we roll the carpet under our feets?
      if rollover? && @bucket_lock.try_lock
        @last_bucket_rollover = Time.now
        @buckets << Bucket.new
      end

      @buckets.last
    end

    def rollover?
      Time.now - @last_bucket_rollover
    end

    def monitor
      Concurrent::TimerTask.new(:execution_interval => 10) do
        reset_buckets
      end.execute
    end

    def reset_buckets
      @buckets = []
    end
  end

  # contain multiples buckets
  class SnapShot
    def initialize(buckets)
    end
  end
end; end
