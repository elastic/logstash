# encoding: utf-8
require "logstash/instrument/metric"

module LogStash module Instrument
 # This class is used in the context when we disable the metric collection
 # for specific plugin to replace the `NamespacedMetric` class with this one
 # which doesn't produce any metric to the collector.
 class NullMetric
    attr_reader :namespace_name

   # Get only the instance methods defined in the class
   # and not the whole hierarchy of methods.
   LogStash::Instrument::Metric.public_instance_methods(false).each do |method|
      define_method method do |key, *args|
      end
   end

   # We have to manually redefine this method since it can return an
   # object this object also has to be implemented as a NullObject
   def time(key)
     if block_given?
       yield
     else
       NullTimedExecution
     end
   end

   def namespace(key)
      self.class.new
   end

   private
   # Null implementation of the internal timer class
   #
   # @see LogStash::Instrument::TimedExecution`
   class NullTimedExecution
     def self.stop
     end
   end
 end
end; end
