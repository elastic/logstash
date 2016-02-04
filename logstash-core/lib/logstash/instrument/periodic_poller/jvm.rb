# encoding: utf-8
require "logstash/instrument/periodic_poller/base"
require 'monitoring'

module LogStash module Instrument module PeriodicPoller
  class JVM < Base

    attr_reader :heap_metrics, :non_heap_metrics, :pools_metrics

    def initialize(metric, options = {})
      super(metric, options)
      jvm_metrics      = metric.namespace(:jvm)
      memory_metrics   = jvm_metrics.namespace(:memory)
      @heap_metrics     = memory_metrics.namespace(:heap)
      @non_heap_metrics = memory_metrics.namespace(:non_heap)
      @pools_metrics = memory_metrics.namespace(:pools)
    end

    def collect
      raw = JRMonitor.memory.generate
      collect_heap_metrics(raw)
      collect_non_heap_metrics(raw)
      collect_pools_metrics(raw)
    end

    private

    def collect_heap_metrics(data)
      heap = aggregate_information_for(data["heap"].values)
      heap[:used_percent] = (heap[:used_in_bytes] / heap[:max_in_bytes].to_f)*100.0

      heap.each_pair do |key, value|
        heap_metrics.gauge(key, value.to_i)
      end
    end

    def collect_non_heap_metrics(data)
      non_heap = aggregate_information_for(data["non_heap"].values)
      non_heap.each_pair do |key, value|
        non_heap_metrics.gauge(key, value.to_i)
      end
    end

    def collect_pools_metrics(data)
      metrics = build_pools_metrics(data)
      metrics.each_pair do |key, hash|
        metric = pools_metrics.namespace(key.to_sym)
        hash.each_pair do |p,v|
          metric.gauge(p, v)
        end
      end
    end

    def build_pools_metrics(data)
      {
        "young"    => aggregate_information_for(data["heap"]["Par Eden Space"]),
        "old"      => aggregate_information_for(data["heap"]["CMS Old Gen"]),
        "survivor" => aggregate_information_for(data["heap"]["Par Survivor Space"]),
      }
    end

    def aggregate_information_for(collection)
      collection.reduce(default_information_accumulator) do |m,e|
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

    def default_information_accumulator
      {
        :used_in_bytes => 0,
        :committed_in_bytes => 0,
        :max_in_bytes => 0,
        :peak_used_in_bytes => 0,
        :peak_max_in_bytes  => 0
      }
    end

  end
end; end; end
