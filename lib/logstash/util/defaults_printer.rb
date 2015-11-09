# encoding: utf-8
require "logstash/namespace"
require "logstash/util"
require "logstash/util/worker_threads_default_printer"


# This class exists to format the settings for defaults used
module LogStash module Util class DefaultsPrinter
  def self.print(settings)
    new(settings).print
  end

  def initialize(settings)
    @settings = settings
    @printers = [workers]
  end

  def print
    collector = []
    @printers.each do |printer|
      printer.visit(collector)
    end
    "Settings: " + collector.join(', ')
  end

  private

  def workers
    WorkerThreadsDefaultPrinter.new(@settings)
  end
end end end
