# encoding: utf-8
require "logstash/util/loggable"

module LogStash module Instrument
  class Snapshot
    include LogStash::Util::Loggable

    attr_reader :metric_store, :created_at

    def initialize(metric_store, created_at = Time.now)
      @metric_store = metric_store
      @created_at = created_at
    end
  end
end; end
