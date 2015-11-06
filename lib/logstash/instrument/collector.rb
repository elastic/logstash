# encoding: utf-8
require "thread"

module LogStash module Instrument
  class Snapshot
    def initialize(head, tail)
    end

    # when a snapshot is deleted we can free the underlying structure
    # A snapshot represent a `bucket of data` and its only a reference to the main structure
    # this should be a matter of changing the head to a specifc item
  end

  class Collector
    attr_reader :collected_metrics

    # pub/sub async, we batch event to the reporters
    # we do not copy data we give a reference from the snapshot
    # use `concurrent-linked` list
    def initialize
      @collected_metrics = []
      @snapshots = []
    end

    def push(metric)
      collected_metrics << metric
    end
  end

  class SnapShotInterval
    def initialize(collector, interval)
    end

    def monitor
    end
  end
end; end
