# encoding: utf-8
require "logstash/instrument/periodic_poller/abstract_poller"

module LogStash module Instrument module PeriodicPoller
  class Os < AbstractPoller
    def initialize(metric, options = {})
      super(interval)
    end

    def collect
    end
  end
end; end; end
