# encoding: utf-8
require "logstash/instrument/snapshot"
require "logstash/util/loggable"
require "concurrent/map"
require "observer"
require "thread"

module LogStash module Instrument
  class Collector
    # TODO: move to a timer based  API with concurrent ruby timer class
    # Allow to accept an external flush
    # When the flush is done we should not record any new metric
    include LogStash::Util::Loggable
    include Observable

    SNAPSHOT_ROTATION_TIME = 1 #seconds

    def initialize(options = {})
      @snapshot_rotation_time = options.fetch(:snapshot_rotation_time, SNAPSHOT_ROTATION_TIME)
      @snapshot_rotation_mutex = Mutex.new
      rotate_snapshot
    end

    # This part of the code is called from multiple threads
    # TODO: rename to record?
    def push(*args)
      snapshot.push(*args)
    end

    private
    def roll_over?
      Concurrent.monotonic_time - @last_rotation >= @snapshot_rotation_time
    end

    def snapshot
      if roll_over? && @snapshot_rotation_mutex.try_lock 
        # fair rotation of the snapshot done by the winning thread
        # metric could be written in the previous snapshot.
        # Since the snapshot isn't written right away
        # the view of the snapshot should be consistent at the time of
        # writing, if we don't receive any events for 5 secs we wont send it.
        # This might be a problem, for time correlation.
        logger.debug("Rotating snapshot", :last_rotation => @last_rotation) if logger.debug?

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

    def update_last_rotation
      @last_rotation = Concurrent.monotonic_time
    end
  end
end; end
