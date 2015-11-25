# encoding: utf-8
module LogStash module Instrument
 class NullMetric
   attr_reader :collector, :base_key
   def initialize(collector, base_key = nil)
     @collector = collector
     @base_key = base_key
   end

   def increment(key, value = 1)
   end

   def decrement(key, value = 1)
   end

   # might be worth to create a block interface for time based gauge
   def gauge(key, value)
   end

   def namespace(key)
     NullMetric.new(collector, "#{base_key}-#{key}")
   end

   def time(key, &block)
   end
 end
end; end
