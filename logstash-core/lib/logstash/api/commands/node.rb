require "logstash/api/commands/base"

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
        
        def pipeline
          extract_metrics(
            [:stats, :pipelines, :main, :config],
            :workers, :batch_size, :batch_delay
          )
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
            }
          }
        end

        def hot_threads(options={})
          HotThreadsReport.new(self, options)
        end

        class HotThreadsReport
          HOT_THREADS_STACK_TRACES_SIZE_DEFAULT = 10.freeze
          
          def initialize(cmd, options)
            @cmd = cmd
            filter = { :stacktrace_size => options.fetch(:stacktrace_size, HOT_THREADS_STACK_TRACES_SIZE_DEFAULT) }
            jr_dump = JRMonitor.threads.generate(filter)
            @thread_dump = ::LogStash::Util::ThreadDump.new(options.merge(:dump => jr_dump))
          end
          
          def to_s
            hash = to_hash[:hot_threads]
            report =  "#{I18n.t("logstash.web_api.hot_threads.title", :hostname => hash[:hostname], :time => hash[:time], :top_count => @thread_dump.top_count )} \n"
            report << '=' * 80
            report << "\n"
            hash[:threads].each do |thread|
              thread_report = ""
              thread_report = "#{I18n.t("logstash.web_api.
                                hot_threads.thread_title", :percent_of_cpu_time => thread[:percent_of_cpu_time], :thread_state => thread[:state], :thread_name => thread[:name])} \n"
              thread_report = "#{thread[:percent_of_cpu_time]} % of of cpu usage by #{thread[:state]} thread named '#{thread[:name]}'\n"
              thread_report << "#{thread[:path]}\n" if thread[:path]
              thread[:traces].each do |trace|
                thread_report << "\t#{trace}\n"
              end
              report << thread_report
              report << '-' * 80
              report << "\n"
            end
            report
          end

          def to_hash
            hash = { :time => Time.now.iso8601, :busiest_threads => @thread_dump.top_count, :threads => [] }
            @thread_dump.each do |thread_name, _hash|
              thread_name, thread_path = _hash["thread.name"].split(": ")
              thread = { :name => thread_name,
                         :percent_of_cpu_time => cpu_time_as_percent(_hash),
                         :state => _hash["thread.state"]
                       }
              thread[:path] = thread_path if thread_path
              traces = []
              _hash["thread.stacktrace"].each do |trace|
                traces << trace
              end
              thread[:traces] = traces unless traces.empty?
              hash[:threads] << thread
            end
            { :hot_threads => hash }
          end

          def cpu_time_as_percent(hash)
            (((cpu_time(hash) / @cmd.uptime * 1.0)*10000).to_i)/100.0
          end

          def cpu_time(hash)
            hash["cpu.time"] / 1000000.0
          end

        end
      end
    end
  end
end
