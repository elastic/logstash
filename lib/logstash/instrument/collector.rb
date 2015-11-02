# encoding: utf-8
require "thread"

module LogStash module Instrument
  class Collector
    # pub/sub async, we batch event to the reporters
    def initialize
      events = []
    end
    
    def push(metric)
      events << metric
    end
  end
end; end
