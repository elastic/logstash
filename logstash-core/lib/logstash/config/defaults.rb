# encoding: utf-8
require "logstash/namespace"
require "concurrent"

module LogStash module Config module Defaults

  extend self

  def cpu_cores
    Concurrent.processor_count
  end
end end end
