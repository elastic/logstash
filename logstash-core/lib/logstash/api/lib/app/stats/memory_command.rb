# encoding: utf-8
require "app/command"
require 'monitoring'

class LogStash::Api::JvmMemoryCommand < LogStash::Api::Command

  def run
    memory = service.get(:jvm_memory_stats)
    {
      :heap => dump(memory[:heap].marshal_dump),
      :non_heap => dump(memory[:non_heap].marshal_dump),
      :pools => memory[:pools].marshal_dump.inject({}) do |acc, (type, hash)|
                  acc[type] = dump(hash.marshal_dump)
                  acc
                end
    }
  rescue
    {} # Something happen, so we just return an empty hash.
  end

  private

  def dump(hash)
    hash.inject({}) do |h, (k,v)|
      h[k] = v.value
      h
    end
  end

end
