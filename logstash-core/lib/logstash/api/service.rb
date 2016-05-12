# encoding: utf-8
require "logstash/instrument/collector"
require "logstash/util/loggable"

module LogStash
  module Api
    class Service

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
        logger.debug("[api-service] snapshot received", :snapshot_time => snapshot.created_at) if logger.debug?

        @snapshot_rotation_mutex.synchronize do
          @snapshot = snapshot
        end
      end

      def snapshot
        @snapshot_rotation_mutex.synchronize { @snapshot }
      end

      def get_shallow(*path)
        snapshot.metric_store.get_shallow(*path)
      end

      def get(key)
        metric_store = @snapshot_rotation_mutex.synchronize { @snapshot.metric_store }
        if key == :jvm_memory_stats
          data = metric_store.get_shallow(:jvm, :memory)
        else
          data = metric_store.get_with_path("stats/events")
        end
        LogStash::Json.dump(data)
      end

      private

      def has_counters?
        (["LogStash::Instrument::MetricType::Counter", "LogStash::Instrument::MetricType::Gauge"] - metric_types).empty?
      end

      def metric_types
        types = []
        @snapshot_rotation_mutex.synchronize do
          types = @snapshot.metric_store.all.map { |t| t.class.to_s }
        end
        return types
      end
    end
  end
end
