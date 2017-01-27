# encoding: utf-8
require "logstash/api/commands/base"
require_relative "hot_threads_reporter"

module LogStash
  module Api
    module Commands
      class Node < Commands::Base

        def all(selected_fields=[])
          payload = {
            :pipeline => pipeline,
            :os => os,
            :jvm => jvm
          }
          payload.select! { |k,v| selected_fields.include?(k) } unless selected_fields.empty?
          payload
        end

        def pipeline(pipeline_id = LogStash::SETTINGS.get("pipeline.id").to_sym)
          stats = extract_metrics(
            [:stats, :pipelines, pipeline_id, :config],
            :workers, :batch_size, :batch_delay, :config_reload_automatic, :config_reload_interval
          )
          stats.merge(:id => pipeline_id)
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
            :vm_name => java.lang.System.getProperty("java.vm.name"),
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
