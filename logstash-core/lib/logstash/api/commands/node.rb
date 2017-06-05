# encoding: utf-8
require "logstash/api/commands/base"
require_relative "hot_threads_reporter"

module LogStash
  module Api
    module Commands
      class Node < Commands::Base

        def all(selected_fields=[])
          payload = {
            :pipelines => pipelines,
            :os => os,
            :jvm => jvm
          }
          payload.select! { |k,v| selected_fields.include?(k) } unless selected_fields.empty?
          payload
        end

        def pipelines
          pipeline_ids = service.get_shallow(:stats, :pipelines).keys
          pipeline_ids.each_with_object({}) do |pipeline_id, result|
            result[pipeline_id] = pipeline(pipeline_id)
          end
        end

        def pipeline(pipeline_id)
          extract_metrics(
            [:stats, :pipelines, pipeline_id.to_sym, :config],
            :workers, :batch_size, :batch_delay, :config_reload_automatic, :config_reload_interval, :dead_letter_queue_enabled, :dead_letter_queue_path
          ).reject{|_, v|v.nil?}
        rescue
          {}
        end

        def os
          {
            :name => java.lang.System.getProperty("os.name"),
            :arch => java.lang.System.getProperty("os.arch"),
            :version => java.lang.System.getProperty("os.version"),
            :available_processors => java.lang.Runtime.getRuntime().availableProcessors()
          }
        end

        def jvm
          memory_bean = ManagementFactory.getMemoryMXBean()

          {
            :pid =>  ManagementFactory.getRuntimeMXBean().getName().split("@").first.to_i,
            :version => java.lang.System.getProperty("java.version"),
            :vm_version => java.lang.System.getProperty("java.version"),
            :vm_vendor => java.lang.System.getProperty("java.vendor"),
            :vm_name => java.lang.System.getProperty("java.vm.name"),
            :start_time_in_millis => started_at,
            :mem => {
              :heap_init_in_bytes => (memory_bean.getHeapMemoryUsage().getInit() < 0 ? 0 : memory_bean.getHeapMemoryUsage().getInit()),
              :heap_max_in_bytes => (memory_bean.getHeapMemoryUsage().getMax() < 0 ? 0 : memory_bean.getHeapMemoryUsage().getMax()),
              :non_heap_init_in_bytes => (memory_bean.getNonHeapMemoryUsage().getInit() < 0 ? 0 : memory_bean.getNonHeapMemoryUsage().getInit()),
              :non_heap_max_in_bytes => (memory_bean.getNonHeapMemoryUsage().getMax() < 0 ? 0 : memory_bean.getNonHeapMemoryUsage().getMax())
            },
            :gc_collectors => ManagementFactory.getGarbageCollectorMXBeans().collect(&:getName)
          }
        end

        def hot_threads(options={})
          HotThreadsReport.new(self, options)
        end
      end
    end
  end
end
