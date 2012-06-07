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

  # Wrap SizedQueue#<< with a timer metric.
  def <<(*args)
    @metric_queue_write.time do
      super(*args)
    end
  end # def <<

  # push should call <<
  def push(*args)
    self << *args
  end # def push
end
