# encoding: utf-8
require "logstash/instrument/periodic_poller/base"

module LogStash module Instrument module PeriodicPoller
  class PersistentQueue < Base
    def initialize(metric, queue_type, agent, options = {})
      super(metric, options)
      @metric = metric
      @queue_type = queue_type
      @agent = agent
    end

    def collect
      pipelines = @agent.get_running_user_defined_pipelines
      unless pipelines.nil?
        pipelines.each {|_, pipeline|
          unless pipeline.nil?
            pipeline.collect_stats
          end
        }
      end
    end
  end
end; end; end
