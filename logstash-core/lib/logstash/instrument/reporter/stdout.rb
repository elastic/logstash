# encoding: utf-8
require "logstash/util/loggable"

module LogStash module Instrument module Reporter
  class Stdout
    include LogStash::Util::Loggable

    def initialize(collector)
      collector.add_observer(self)
    end

    def update(snapshot)
      logger.error("Reporter Stdout", :time => snapshot.created_at, :snapshot => snapshot.inspect)
    end
  end
end; end; end
