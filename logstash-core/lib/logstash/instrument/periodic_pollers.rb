# encoding: utf-8
require "logstash/instrument/periodic_poller/dlq"
require "logstash/instrument/periodic_poller/os"
require "logstash/instrument/periodic_poller/jvm"
require "logstash/instrument/periodic_poller/pq"

module LogStash module Instrument
  # Each PeriodPoller manager his own thread to do the poller
  # of the stats, this class encapsulate the starting and stopping of the poller
  # if the unique timer uses too much resource we can refactor this behavior here.
  class PeriodicPollers
    attr_reader :metric

    def initialize(metric, queue_type, pipelines)
      @metric = metric
      @periodic_pollers = [PeriodicPoller::Os.new(metric),
                           PeriodicPoller::JVM.new(metric),
                           PeriodicPoller::PersistentQueue.new(metric, queue_type, pipelines),
                           PeriodicPoller::DeadLetterQueue.new(metric, pipelines)]
    end

    def start
      @periodic_pollers.map(&:start)
    end

    def stop
      @periodic_pollers.map(&:stop)
    end
  end
end; end
