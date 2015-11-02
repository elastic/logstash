# encoding: utf-8
require "concurrent/array"
module LogStash module Instrument
  class Collector
    def initialize
      events = Concurrent::Array.new
    end
    
    def insert(metric)
      events << metric
    end
  end
end; end
