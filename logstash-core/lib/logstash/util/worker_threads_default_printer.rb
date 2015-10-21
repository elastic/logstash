# encoding: utf-8
require "logstash/namespace"
require "logstash/util"

# This class exists to format the settings for default worker threads
module LogStash module Util class WorkerThreadsDefaultPrinter

  def initialize(settings)
    @setting = settings.fetch('filter-workers', 1)
  end

  def visit(collector)
    collector.push "Filter workers: #{@setting}"
  end

end end end

