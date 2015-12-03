# encoding: utf-8
require "logstash/instrument/periodic_poller_observer"
require "logstash/util/loggable"
require "concurrent"

module LogStash module Instrument module PeriodicPoller
  class AbstractPoller
    include LogStash::Util::Loggable

    DEFAULT_POLLING_INTERVAL = 5

    def initialize(interval = DEFAULT_POLLING_INTERVAL)
      @interval = interval

      @task = Concurrent::TimerTask.new { collect }
      @task.execution_interval = interval
      @task.timeout_interval = interval # Fetching statistic should be almost instant
      # No need to create a special Observer here just use this classe and add the update to the abstract class?
      # TODO
      @task.add_observer(PeriodicPollerObserver.new(self))
    end

    def collect
      raise NotImplementedError, "#{self.class.name} need to implement `#collect`"
    end

    def start
      logger.debug("PeriodicPoller: Starting", :poller => self,
                   :interval => @interval) if logger.debug?
      @task.execute
    end

    def stop
      logger.debug("PeriodicPoller: Stopping", :poller => self)
      @task.shutdown
    end
  end
end
end; end; end
