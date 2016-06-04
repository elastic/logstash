require "logstash/api/commands/base"
require 'logstash/util/thread_dump'

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
            )
          }
        end

        def process
          extract_metrics(
            [:jvm, :process],
            :open_file_descriptors,
            :peak_open_file_descriptors,
            :max_file_descriptors,
            [:mem, [:total_virtual_in_bytes]],
            [:cpu, [:total_in_millis, :percent]]
          )
        end

        def events
          extract_metrics(
            [:stats, :events],
            :in, :filtered, :out
          )
        end

        def pipeline
          service.get_shallow(:stats, :pipelines)
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
      end
    end
  end
end
