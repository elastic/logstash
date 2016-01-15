# encoding: utf-8
require "logstash/instrument/collector"
require "logstash/util/loggable"

class LogStash::Api::Service

  include Singleton
  include LogStash::Util::Loggable

  def initialize
    @snapshot_rotation_mutex = Mutex.new
    @snapshot = nil
    logger.debug("[api-service] start") if logger.debug?
    LogStash::Instrument::Collector.instance.add_observer(self)
  end

  def stop
    logger.debug("[api-service] stop") if logger.debug?
    LogStash::Instrument::Collector.instance.delete_observer(self)
  end

  def update(snapshot)
    logger.debug("[api-service] snapshot received", :snapshot => snapshot) if logger.debug?
    if @snapshot_rotation_mutex.try_lock
      @snapshot = snapshot
      @snapshot_rotation_mutex.unlock
    end
  end

  def get(key)
    metric_store = @snapshot.metric_store
    if key == :jvm_memory_stats
      metric_store.get(:root, :jvm, :memory)
    else
      { :base => metric_store.get(:root, :base) }
    end
  rescue
    {}
  end
end
