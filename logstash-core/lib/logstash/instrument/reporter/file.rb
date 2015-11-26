# encoding: utf-8
require "logstash/instrument/reporter/base"

module Logstash module Instrument module Reporter
  class File < Base
    def initialize(collector)
      super(collector)
    end
  end
end; end; end
