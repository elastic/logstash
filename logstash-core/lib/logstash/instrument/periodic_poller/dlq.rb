# encoding: utf-8
require 'logstash/instrument/periodic_poller/base'

module LogStash module Instrument module PeriodicPoller
  class DeadLetterQueue < Base
    def initialize(metric, agent, options = {})
      super(metric, options)
      @metric = metric
      @agent = agent
    end

    def collect
      pipelines = @agent.get_running_user_defined_pipelines
      unless pipelines.nil?
        pipelines.each {|_, pipeline|
          unless pipeline.nil?
            pipeline.collect_dlq_stats
          end
        }
      end
    end
  end
end end end

