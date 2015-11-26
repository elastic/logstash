# encoding: utf-8
require "logstash/instrument/reporter/base"
require "logstash/util/loggable"

module LogStash module Instrument module Reporter
  class Stdout < Base
    include LogStash::Util::Loggable

    def initialize(collector)
      super(collector)
    end

    def update(time, snapshot)
      logger.error("Reporter Stdout", :time => time, :snapshot_size => snapshot.size, :snapshot => snapshot.inspect)
    end
  end
end; end; end
