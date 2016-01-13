# encoding: utf-8
require "app/command"
require 'monitoring'

class LogStash::Api::JvmMemoryCommand < LogStash::Api::Command

  def run
    { :memory => build }
  end

  def build
    raw      = JRMonitor.memory.generate
    heap     = build_heap_metrics(raw)
    non_heap = build_non_heap_metrics(raw)
    { :heap => heap, :non_heap => non_heap}
  end

  private

  def build_heap_metrics(data)
    heap = aggregate_information_for(data, "heap")
    heap[:used_percent] = (heap[:used_in_bytes] / heap[:max_in_bytes].to_f)*100
    heap
  end

  def build_non_heap_metrics(data)
    aggregate_information_for(raw_data, "non_heap")
  end

  def aggregate_information_for(raw_data, type)
   raw_data[type].values.reduce({:used_in_bytes => 0, :committed_in_bytes => 0, :max_in_bytes => 0}) do |m,e|
      e.each_pair do |k,v|
        if k.include?("used")
          m[:used_in_bytes] += v
        elsif k.include?("committed")
          m[:committed_in_bytes] += v
        elsif k.include?("max")
          m[:max_in_bytes] += v
        end
      end
      m
    end
  end

end
