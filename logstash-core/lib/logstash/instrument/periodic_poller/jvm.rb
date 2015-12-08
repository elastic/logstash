# encoding: utf-8
require "logstash/instrument/periodic_poller/abstract_poller"

module LogStash module Instrument module PeriodicPoller
  class JVM < AbstractPoller
    def initialize(metric, options = {})
      super(metric, options)
    end

    def collect
    end
  end
end; end; end
