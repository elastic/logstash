# encoding: utf-8
require "logstash/instrument/periodic_poller/base"

module LogStash module Instrument module PeriodicPoller
  class Os < Base
    def initialize(metric, options = {})
      super(metric, options)
    end

    def collect
    end
  end
end; end; end
