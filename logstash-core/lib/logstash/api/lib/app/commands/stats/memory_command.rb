# encoding: utf-8
require "app/command"
require 'monitoring'

class LogStash::Api::JvmMemoryCommand < LogStash::Api::Command

  def run
    report = { :pools => {} }
    memory = LogStash::Json.load(service.get(:jvm_memory_stats))

    report.merge!(add_heap_report_data_using(memory))    if memory.keys.include?("heap")
    report.merge!(add_nonheap_report_data_using(memory)) if memory.keys.include?("non_heap")
    report[:pools].merge!(add_pools_data_using(memory))  if memory.keys.include?("pools")
    report
  end

  private

  def add_pools_data_using(memory)
    memory["pools"].inject({}) do |acc, (type, hash)|
      hash.delete("committed_in_bytes")
      acc[type] = hash
      acc
    end
  end

  def add_nonheap_report_data_using(memory)
    {
      :non_heap_used_in_bytes      => memory["non_heap"]["used_in_bytes"],
      :non_heap_committed_in_bytes => memory["non_heap"]["committed_in_bytes"],
    }
  end

  def add_heap_report_data_using(memory)
    {
      :heap_used_in_bytes      => memory["heap"]["used_in_bytes"],
      :heap_used_percent       => memory["heap"]["used_percent"],
      :heap_committed_in_bytes => memory["heap"]["committed_in_bytes"],
      :heap_max_in_bytes       => memory["heap"]["max_in_bytes"],
      :heap_used_in_bytes      => memory["heap"]["used_in_bytes"],
    }
  end

end
