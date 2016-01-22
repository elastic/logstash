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

    def register
    end

    def run(queue)
      @logger.debug("Metric: input started")
      @queue = queue

      # we register to the collector after receiving the pipeline queue
      LogStash::Instrument::Collector.instance.add_observer(self)

      # Keep this plugin thread alive,
      # until we shutdown the metric pipeline
      sleep(1) while !stop?
    end

    def stop
      @logger.debug("Metrics input: stopped")
      LogStash::Instrument::Collector.instance.delete_observer(self)
    end

    def update(snapshot)
      @logger.debug("Metrics input: received a new snapshot", :created_at => snapshot.created_at, :snapshot => snapshot, :event => snapshot.metric_store.to_event) if @logger.debug?

      # TODO: (ph)
      # - Obviously the format here is wrong and we need to
      # transform it from Snapshot to an event
      # - There is another problem, if the queue is full this could block the snapshot thread.
      # There is a few possible solution for this problem:
      #   - We can use a future
      #   - We can use a synchronization mechanism between the called thread (update method)
      #   and the plugin thread (run method)
      #   - How we handle back pressure here?
      #   - one snashot should be only one event ?
      snapshot.metric_store.each do |metric|
        @queue << LogStash::Event.new({ "@timestamp" => snapshot.created_at }.merge(metric.to_hash))
      end
    end
  end
end;end
