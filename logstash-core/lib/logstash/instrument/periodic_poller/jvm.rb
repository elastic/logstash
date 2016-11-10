
# encoding: utf-8
require "logstash/instrument/periodic_poller/base"
require "jrmonitor"
require "set"

java_import 'java.lang.management.ManagementFactory'
java_import 'java.lang.management.OperatingSystemMXBean'
java_import 'java.lang.management.GarbageCollectorMXBean'
java_import 'java.lang.management.RuntimeMXBean'
java_import 'com.sun.management.UnixOperatingSystemMXBean'
java_import 'javax.management.MBeanServer'
java_import 'javax.management.ObjectName'
java_import 'javax.management.AttributeList'
java_import 'javax.naming.directory.Attribute'


module LogStash module Instrument module PeriodicPoller
  class JVM < Base
    class GarbageCollectorName
      YOUNG_GC_NAMES = Set.new(["Copy", "PS Scavenge", "ParNew", "G1 Young Generation"])
      OLD_GC_NAMES = Set.new(["MarkSweepCompact", "PS MarkSweep", "ConcurrentMarkSweep", "G1 Old Generation"])

      YOUNG = :young
      OLD = :old

      def self.get(gc_name)
        if YOUNG_GC_NAMES.include?(gc_name)
          YOUNG
        elsif(OLD_GC_NAMES.include?(gc_name))
          OLD
        end
      end
    end

    attr_reader :metric

    def initialize(metric, options = {})
      super(metric, options)
      @metric = metric
    end

    def collect
      raw = JRMonitor.memory.generate
      collect_jvm_metrics(raw)      
      collect_pools_metrics(raw)
      collect_threads_metrics
      collect_process_metrics
      collect_gc_stats      
    end

    private

    def collect_gc_stats
      garbage_collectors = ManagementFactory.getGarbageCollectorMXBeans()

      garbage_collectors.each do |collector|
        name = GarbageCollectorName.get(collector.getName())
        if name.nil?
          logger.error("Unknown garbage collector name", :name => name)
        else
          metric.gauge([:jvm, :gc, :collectors, name], :collection_count, collector.getCollectionCount())
          metric.gauge([:jvm, :gc, :collectors, name], :collection_time_in_millis, collector.getCollectionTime())
        end
      end
    end

    def collect_threads_metrics
      threads = JRMonitor.threads.generate

      current = threads.count
      if @peak_threads.nil? || @peak_threads < current
        @peak_threads = current
      end

      metric.gauge([:jvm, :threads], :count, threads.count)
      metric.gauge([:jvm, :threads], :peak_count, @peak_threads)
    end

    def collect_process_metrics
      process_metrics = JRMonitor.process.generate

      path = [:jvm, :process]


      open_fds = process_metrics["open_file_descriptors"]
      if @peak_open_fds.nil? || open_fds > @peak_open_fds
        @peak_open_fds = open_fds
      end
      metric.gauge(path, :open_file_descriptors, open_fds)
      metric.gauge(path, :peak_open_file_descriptors, @peak_open_fds)
      metric.gauge(path, :max_file_descriptors, process_metrics["max_file_descriptors"])

      cpu_path = path + [:cpu]
      cpu_metrics = process_metrics["cpu"]
      metric.gauge(cpu_path, :percent, cpu_metrics["process_percent"])
      metric.gauge(cpu_path, :total_in_millis, cpu_metrics["total_in_millis"])

      metric.gauge(path + [:mem], :total_virtual_in_bytes, process_metrics["mem"]["total_virtual_in_bytes"])
    end
    
    def collect_jvm_metrics(data)
      runtime_mx_bean = ManagementFactory.getRuntimeMXBean()
      metric.gauge([:jvm], :uptime_in_millis, runtime_mx_bean.getUptime())
      collect_heap_metrics(data)
      collect_non_heap_metrics(data)
    end  

    def collect_heap_metrics(data)
      heap = aggregate_information_for(data["heap"].values)      
      heap[:used_percent] = (heap[:used_in_bytes] / heap[:max_in_bytes].to_f)*100.0

      heap.each_pair do |key, value|
        metric.gauge([:jvm, :memory, :heap], key, value.to_i)
      end
    end

    def collect_non_heap_metrics(data)
      non_heap = aggregate_information_for(data["non_heap"].values)
      non_heap.each_pair do |key, value|
        metric.gauge([:jvm, :memory, :non_heap],key, value.to_i)
      end
    end

    def collect_pools_metrics(data)
      metrics = build_pools_metrics(data)
      metrics.each_pair do |key, hash|
        hash.each_pair do |p,v|
          metric.gauge([:jvm, :memory, :pools, key.to_sym], p, v)
        end
      end
    end


    def build_pools_metrics(data)
      heap = data["heap"]
      old  = {}
      old = old.merge!(heap["CMS Old Gen"]) if heap.has_key?("CMS Old Gen")
      old = old.merge!(heap["PS Old Gen"])  if heap.has_key?("PS Old Gen")
      young = {}
      young = young.merge!(heap["Par Eden Space"]) if heap.has_key?("Par Eden Space")
      young = young.merge!(heap["PS Eden Space"])  if heap.has_key?("PS Eden Space")
      survivor = {}
      survivor = survivor.merge!(heap["Par Survivor Space"]) if heap.has_key?("Par Survivor Space")
      survivor = survivor.merge!(heap["PS Survivor Space"])  if heap.has_key?("PS Survivor Space")
      {
        "young"    => aggregate_information_for(young),
        "old"      => aggregate_information_for(old),
        "survivor" => aggregate_information_for(survivor)
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
        :peak_max_in_bytes => 0
      }
    end
  end
end; end; end
