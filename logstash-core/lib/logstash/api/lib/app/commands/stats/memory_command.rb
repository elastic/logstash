# encoding: utf-8
require "app/command"
require 'monitoring'

class LogStash::Api::JvmMemoryCommand < LogStash::Api::Command

  def run
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

end
