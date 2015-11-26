# encoding: utf-8
require "logstash/instrument/concurrent_linked_queue"
require "cabin"
require "concurrent/map"
require "observer"
require "thread"

module LogStash module Instrument
  module Loggable
    @logger = Cabin::Channel.get(LogStash)
    def self.logger=(new_logger)
      @logger = new_logger
    end

    def self.logger
      @logger
    end
  end

  class Collector
    include Observable
    include Loggable

    SNAPSHOT_ROTATION_TIME = 1 #seconds

    def initialize(options = {})
      @snapshot_rotation_time = options.fetch(:snapshot_rotation_time, SNAPSHOT_ROTATION_TIME)
      @snapshot_rotation_mutex = Mutex.new
      rotate_snapshot
    end

    def roll_over?
      Concurrent.monotonic_time - @last_rotation >= @snapshot_rotation_time
    end

    # This part of the code is called from multiple thread
    # TODO: rename to record?
    def push(*args)
      snapshot.push(*args)
    end

    def snapshot
      if roll_over? && @snapshot_rotation_mutex.try_lock 
        # fair rotation of the snapshot done by the winning thread
        # metric could be written in the previous snapshot.
        # Since the snapshot isn't written right away
        # the view of the snapshot should be consistent at the time of
        # writing, if we don't receive any events for 5 secs we wont send it.
        # This might be a problem, for time correlation.
        publish_snapshot
        rotate_snapshot
        @snapshot_rotation_mutex.unlock
      end

      @current_snapshot
    end

    def rotate_snapshot
      @current_snapshot = Snapshot.new
      update_last_rotation
    end

    def publish_snapshot
      notify_observers(Concurrent.monotonic_time, @current_snapshot) 
    end

    private
    def update_last_rotation
      @last_rotation = Concurrent.monotonic_time
    end
  end

  class Reporter
    include Loggable

    def initialize(collector)
      collector.add_observer(self)
    end

    def update(time, snapshot)
      logger.warn("Received a new Snapshot", :metrics_size => snapshot.size)
    end
  end

  class Snapshot
    def initialize
      # The Map doesn't respect the order of insertion
      # we have to track the time another way
      @metrics = Concurrent::Map.new
    end
    
    def push(*args)
      type, key, _ = args
      metric = @metrics.fetch_or_store(key, concrete_class(type))
      metric.execute(*args)
    end

    def concrete_class(type)
      # TODO, benchmark, I think this is faster than using constantize
      case type
      when :counter then Counter.new
      end
    end

    def size
      @metrics.size
    end
  end

  class Counter
    def initialize(value = 0)
      # This should be a `LongAdder`,
      # will have to create a rubyext for it and support jdk7
      # look at the elasticsearch source code.
      # LongAdder only support decrement of one?
      # Most of the time we will be adding
      @counter = Concurrent::AtomicFixnum.new(value)
    end

    def increment(value = 1)
      @counter.increment(value)
    end

    def decrement(value = 1)
      @counter.decrement(value)
    end

    def execute(type, key, action, time, value)
      @counter.send(action, value)
    end
  end
end; end
