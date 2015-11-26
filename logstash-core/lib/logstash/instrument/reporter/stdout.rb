# encoding: utf-8
require "logstash/instrument/reporter/base"

module LogStash module Instrument module Reporter
  class Stdout < Base
    def initialize(collector)
      super(collector)
    end

    def update(time, snapshot)
      puts "Time: #{time}, items: #{snapshot.size}"
    end
  end
end; end; end
