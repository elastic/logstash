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
    @metric_queue_write = @logger.metrics.timer(self, "queue-write")
  end # def logger=

  # Wrap SizedQueue#push with a timer metric.
  def push(*args)
    @metric_queue_write.time do
      super(*args)
    end
  end # def push
  alias_method :<<, :push
end
