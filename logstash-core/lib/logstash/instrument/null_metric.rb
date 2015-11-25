# encoding: utf-8
module LogStash module Instrument
 class NullMetric
   attr_reader :collector, :base_key
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
     NullMetric.new
   end

   def time(key, &block)
   end
 end
end; end
