# encoding: utf-8
require "logstash/util/loggable"
require "logstash/util"
require "concurrent"

module LogStash module Instrument module PeriodicPoller
  class Base
    include LogStash::Util::Loggable

    DEFAULT_OPTIONS = {
      :polling_interval => 1,
      :polling_timeout => 60
    }

    public
    def initialize(metric, options = {})
      @metric = metric
      @options = DEFAULT_OPTIONS.merge(options)
      configure_task
    end

    def update(time, result, exception)
      return unless exception

      logger.error("PeriodicPoller: exception",
                   :poller => self,
                   :result => result,
                   :exception => exception,
                   :executed_at => time)
    end

    def collect
      raise NotImplementedError, "#{self.class.name} need to implement `#collect`"
    end

    def start
      logger.debug("PeriodicPoller: Starting",
                   :polling_interval => @options[:polling_interval],
                   :polling_timeout => @options[:polling_timeout]) if logger.debug?
      
      collect # Collect data right away if possible
      @task.execute
    end

    def stop
      logger.debug("PeriodicPoller: Stopping")
      @task.shutdown
    end

    protected
    def configure_task
      @task = Concurrent::TimerTask.new { collect }
      @task.execution_interval = @options[:polling_interval]
      @task.timeout_interval = @options[:polling_timeout]
      @task.add_observer(self)
    end
  end
end
end; end
