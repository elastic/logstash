# encoding: utf-8
require "app/command"
require 'monitoring'

class LogStash::Api::JvmMemoryCommand < LogStash::Api::Command

  def run
    memory = LogStash::Json.load(service.get(:jvm_memory_stats))
    {
      :heap => memory["heap"],
      :non_heap => memory["non_heap"],
      :pools => memory["pools"].inject({}) do |acc, (type, hash)|
                  acc[type] = hash
                  acc
               end
    }
  rescue
    {} # Something happen, so we just return an empty hash.
  end

end
