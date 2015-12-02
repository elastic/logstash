# encoding: utf-8
require "logstash/inputs/base"
require "logstash/instrument/collector"

module LogStash module Inputs
  class Metrics < LogStash::Inputs::Base
    config_name "metrics"

    def register
    end

    def run(queue)
      LogStash::Instrument::Collector.instance.add_observer(self)

      @queue = queue

      # Keep this plugin thread alive,
      # until we shutdown the metric pipeline
      sleep(1) while !stop
    end

    def update(time, snapshot)
      # TODO: 
      # - Obviously the format here is wrong and we need to
      # transform it from Snapshot to an event
      # - There is another problem, if the queue is full this could block the snapshot thread.
      # There is a few possible solution for this problem:
      #   - We can use a future
      #   - We can use a synchronization mechanism between the called thread (update method)
      #   and the plugin thread (run method)
      @queue << Logstash::Event.new(snapshot.to_event)
    end
  end
end;end
