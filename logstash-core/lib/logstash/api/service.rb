# encoding: utf-8
require "logstash/instrument/collector"
require "logstash/util/loggable"

module LogStash
  module Api
    class Service
      include LogStash::Util::Loggable

      attr_reader :agent

      def initialize(agent)
        @agent = agent
        logger.debug("[api-service] start") if logger.debug?
      end

      def started?
        true
      end

      def snapshot
        agent.metric.collector.snapshot_metric
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
        true
      end
    end
  end
end
