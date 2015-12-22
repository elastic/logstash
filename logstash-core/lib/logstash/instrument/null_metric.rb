# encoding: utf-8
require "logstash/instrument/metric"

module LogStash module Instrument
 class NullMetric
   class NullTimedExecution
     def self.stop
     end
   end

   # Allow to reuse the same variable when creating subnamespace
   NULL_METRIC_INSTANCE = NullMetric.new

   attr_reader :collector, :namespace_information
   def initialize
   end

   def increment(key, value = 1)
   end

   def decrement(key, value = 1)
   end

   # might be worth to create a block interface for time based gauge
   def gauge(key, value)
   end

   def namespace(key)
     NULL_METRIC_INSTANCE
   end

   def report_time(key, duration)
   end

   def time(key)
     if block_given?
       yield 
     else
       NullTimedExecution
     end
   end
 end
end; end
