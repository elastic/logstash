# encoding: utf-8
require "thread"

module LogStash module Instrument
  class Collector
    # pub/sub async, we batch event to the reporters
    # we do not copy data we give a reference from the snapshot
    # use `concurrent-linked` list
    def initialize
    end

    def push(metric)
    end
  end
end; end
