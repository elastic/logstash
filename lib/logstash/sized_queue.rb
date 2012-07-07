require "logstash/namespace"
require "logstash/logging"
require "thread" # for SizedQueue

class LogStash::SizedQueue < SizedQueue
  attr_accessor :logger

  # Set the logger for this queue
  #
  # This will also configure any metrics for this queue.
  public
  def logger=(_logger)
    @logger = _logger
  end # def logger=

  alias_method :<<, :push
end
