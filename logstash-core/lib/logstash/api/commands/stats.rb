require "logstash/api/commands/base"
require 'logstash/util/thread_dump'

module LogStash
  module Api
    module Commands
      class Stats < Commands::Base

        def jvm
          {:threads => service.get_shallow(:jvm, :threads)}
        end

        def process
          service.get_shallow(:jvm, :process)
        end

        def events
          service.get_shallow(:stats, :events)
        end

        def memory
          memory = LogStash::Json.load(service.get(:jvm_memory_stats))
          {
            :heap_used_in_bytes => memory["heap"]["used_in_bytes"],
            :heap_used_percent => memory["heap"]["used_percent"],
            :heap_committed_in_bytes => memory["heap"]["committed_in_bytes"],
            :heap_max_in_bytes => memory["heap"]["max_in_bytes"],
            :heap_used_in_bytes => memory["heap"]["used_in_bytes"],
            :non_heap_used_in_bytes => memory["non_heap"]["used_in_bytes"],
            :non_heap_committed_in_bytes => memory["non_heap"]["committed_in_bytes"],
            :pools => memory["pools"].inject({}) do |acc, (type, hash)|
              hash.delete("committed_in_bytes")
              acc[type] = hash
              acc
            end
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
            hash = to_hash
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
            hash = { :hostname => @cmd.hostname, :time => Time.now.iso8601, :busiest_threads => @thread_dump.top_count, :threads => [] }
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
            hash
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
