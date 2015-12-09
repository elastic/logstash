# encoding: utf-8
require "logstash/instrument/collector"

class LogStash::Api::Service

  include Singleton

  def initialize
    @snapshot_rotation_mutex = Mutex.new
    @snapshot = nil

    LogStash::Instrument::Collector.instance.add_observer(self)
  end

  def stop
    LogStash::Instrument::Collector.instance.delete_observer(self)
  end

  def update(time, snapshot)
    if @snapshot_rotation_mutex.try_lock
      @snapshot = snapshot
      @snapshot_rotation_mutex.unlock
    end
  end

  def get(key=:service_metrics)
    @snapshot.to_event.to_hash
  rescue
    {}
  end
end
