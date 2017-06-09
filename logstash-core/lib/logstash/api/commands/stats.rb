# encoding: utf-8
require "logstash/api/commands/base"
require 'logstash/util/thread_dump'
require_relative "hot_threads_reporter"

java_import java.nio.file.Files
java_import java.nio.file.Paths

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
            :uptime_in_millis => service.get_shallow(:jvm, :uptime_in_millis),
          }
        end

        def reloads
          service.get_shallow(:stats, :reloads)
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
            :in, :filtered, :out, :duration_in_millis, :queue_push_duration_in_millis
          )
        end

        def pipeline(pipeline_id = nil)
          if pipeline_id.nil?
            pipeline_ids = service.get_shallow(:stats, :pipelines).keys
            pipeline_ids.each_with_object({}) do |pipeline_id, result|
              result[pipeline_id] = plugins_stats_report(pipeline_id)
            end
          else
            { pipeline_id => plugins_stats_report(pipeline_id) }
          end
        rescue # failed to find pipeline
          {}
        end

        def memory
          memory = service.get_shallow(:jvm, :memory)
          {
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

        def os
          service.get_shallow(:os)
        rescue
          # The only currently fetch OS information is about the linux
          # containers.
          {}
        end

        def gc
          service.get_shallow(:jvm, :gc)
        end

        def hot_threads(options={})
          HotThreadsReport.new(self, options)
        end

        private
        def plugins_stats_report(pipeline_id)
          stats = service.get_shallow(:stats, :pipelines, pipeline_id.to_sym)
          PluginsStats.report(stats)
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
            {
              :events => stats[:events],
              :plugins => {
                :inputs => plugin_stats(stats, :inputs),
                :filters => plugin_stats(stats, :filters),
                :outputs => plugin_stats(stats, :outputs)
              },
              :reloads => stats[:reloads],
              :queue => stats[:queue]
            }.merge(stats[:dlq] ? {:dead_letter_queue => stats[:dlq]} : {})
            end
        end # module PluginsStats
      end
    end
  end
end
