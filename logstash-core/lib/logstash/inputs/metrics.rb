# encoding: utf-8
require "logstash/event"
require "logstash/inputs/base"
require "logstash/instrument/collector"

module LogStash module Inputs
  # The Metrics inputs is responable of registring itself to the collector.
  # The collector class will periodically emits new snapshot of the system,
  # The metrics need to take that information and transform it into
  # a `Logstash::Event`, which can be consumed by the shipper and send to
  # Elasticsearch
  class Metrics < LogStash::Inputs::Base
    config_name "metrics"
    milestone 3

    def register
    end

    def run(queue)
      @logger.debug("Metric: input started")
      @queue = queue

      # we register to the collector after receiving the pipeline queue
      metric.collector.add_observer(self)

      # Keep this plugin thread alive,
      # until we shutdown the metric pipeline
      sleep(1) while !stop?
    end

    def stop
      @logger.debug("Metrics input: stopped")
      metric.collector.delete_observer(self)
    end

    def update(snapshot)
      @logger.debug("Metrics input: received a new snapshot", :created_at => snapshot.created_at, :snapshot => snapshot, :event => snapshot.metric_store.to_event) if @logger.debug?

      # The back pressure is handled in the collector's
      # scheduled task (running into his own thread) if something append to one of the listener it will
      # will timeout. In a sane pipeline, with a low traffic of events it shouldn't be a problems.
      snapshot.metric_store.each do |metric|
        @queue << LogStash::Event.new({ "@timestamp" => snapshot.created_at }.merge(metric.to_hash))
      end
    end
  end
end;end
