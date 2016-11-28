# encoding: utf-8
require "logstash/api/commands/base"
require 'logstash/util/thread_dump'
require_relative "hot_threads_reporter"

module LogStash
  module Api
    module Commands
      class Stats < Commands::Base
        def jvm
          {
            :threads => extract_metrics(
              [:jvm, :threads],
              :count,
              :peak_count
            ),
            :mem => memory,
            :gc => gc,
            :uptime_in_millis => service.get_shallow(:jvm, :uptime_in_millis)
          }
        end

        def process
          extract_metrics(
            [:jvm, :process],
            :open_file_descriptors,
            :peak_open_file_descriptors,
            :max_file_descriptors,
            [:mem, [:total_virtual_in_bytes]],
            [:cpu, [:total_in_millis, :percent, :load_average]]
          )
        end

        def events
          extract_metrics(
            [:stats, :events],
            :in, :filtered, :out, :duration_in_millis
          )
        end

        def pipeline
          stats = service.get_shallow(:stats, :pipelines)
          PluginsStats.report(stats)
        end

        def memory
          memory = service.get_shallow(:jvm, :memory)
          {
            :heap_used_in_bytes => memory[:heap][:used_in_bytes],
            :heap_used_percent => memory[:heap][:used_percent],
            :heap_committed_in_bytes => memory[:heap][:committed_in_bytes],
            :heap_max_in_bytes => memory[:heap][:max_in_bytes],
            :heap_used_in_bytes => memory[:heap][:used_in_bytes],
            :non_heap_used_in_bytes => memory[:non_heap][:used_in_bytes],
            :non_heap_committed_in_bytes => memory[:non_heap][:committed_in_bytes],
            :pools => memory[:pools].inject({}) do |acc, (type, hash)|
              hash.delete("committed_in_bytes")
              acc[type] = hash
              acc
            end
          }
        end

        def gc
          service.get_shallow(:jvm, :gc)
        end

        def hot_threads(options={})
          HotThreadsReport.new(self, options)
        end

        module PluginsStats
          module_function

          def plugin_stats(stats, plugin_type)
            # Turn the `plugins` stats hash into an array of [ {}, {}, ... ]
            # This is to produce an array of data points, one point for each
            # plugin instance.
            return [] unless stats[:plugins] && stats[:plugins].include?(plugin_type)
            stats[:plugins][plugin_type].collect do |id, data|
              { :id => id }.merge(data)
            end
          end

          def report(stats)
            # Only one pipeline right now.
            stats = stats[:main]

            {
              :events => stats[:events],
              :plugins => {
                :inputs => plugin_stats(stats, :inputs),
                :filters => plugin_stats(stats, :filters),
                :outputs => plugin_stats(stats, :outputs)
              },
              :reloads => stats[:reloads],
            }
          end
        end # module PluginsStats
      end
    end
  end
end
