# encoding: utf-8
require "app/command"
require 'monitoring'

class LogStash::Api::JvmMemoryCommand < LogStash::Api::Command

  def run
    raw = JRMonitor.memory.generate
    { :heap => build_heap_metrics(raw),
      :non_heap => build_non_heap_metrics(raw),
      :pools => build_pools_metrics(raw) }
  end

  private

  def build_heap_metrics(data)
    heap = aggregate_information_for(data["heap"].values)
    heap[:used_percent] = (heap[:used_in_bytes] / heap[:max_in_bytes].to_f)*100
    heap
  end

  def build_non_heap_metrics(data)
    aggregate_information_for(data["non_heap"].values)
  end

  def build_pools_metrics(data)
    {
      "young"    => aggregate_information_for(data["heap"]["Par Eden Space"]),
      "old"      => aggregate_information_for(data["heap"]["CMS Old Gen"]),
      "survivor" => aggregate_information_for(data["heap"]["Par Survivor Space"]),
    }
  end

  def aggregate_information_for(collection)
    collection.reduce({:used_in_bytes => 0,      :committed_in_bytes => 0, :max_in_bytes => 0, 
                       :peak_used_in_bytes => 0, :peak_max_in_bytes  => 0 }) do |m,e|
      e = { e[0] => e[1] } if e.is_a?(Array)
      e.each_pair do |k,v|
        m[:used_in_bytes] += v       if k.include?("used")
        m[:committed_in_bytes] += v  if k.include?("committed")
        m[:max_in_bytes] += v        if k.include?("max")
        m[:peak_max_in_bytes] += v   if k.include?("peak.max")
        m[:peak_used_in_bytes] += v  if k.include?("peak.used")
      end
      m
    end
  end

end
