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

  def agent
    LogStash::Instrument::Collector.instance.agent
  end

  def started?
    !@snapshot.nil? && has_counters?
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
      data = metric_store.get_with_path("jvm/memory")[:jvm][:memory]
    else
      data = metric_store.get_with_path("stats/events")
    end
    LogStash::Json.dump(data)
  end

  private

  def has_counters?
    return false if @snapshot.nil?
    if @snapshot_rotation_mutex.try_lock
      has = @snapshot.metric_store.all.clone.map { |t| t.class.to_s }.include?("LogStash::Instrument::MetricType::Counter")
      @snapshot_rotation_mutex.unlock
      return has
    end
  end
end
