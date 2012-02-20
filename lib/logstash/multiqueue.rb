require "logstash/namespace"
require "logstash/logging"

class LogStash::MultiQueue
  attr_accessor :logger

  public
  def initialize(*queues)
    @logger = LogStash::Logger.new(STDOUT)
    @mutex = Mutex.new
    @queues = queues
  end # def initialize

  public
  def logger=(_logger)
    @logger = _logger
    @metric_queue_write = @logger.metrics.timer(self, "multiqueue-write")
    @metric_queue_count = @logger.metrics.counter(self, "multiqueue-queues")

    # TODO(sissel): gauge not implemented yet.
    #@metric_queue_items = @logger.metrics.gauge(self, "multiqueue-items") { size }

    # Set the logger for all known queues, too.
    @queues.each do |q|
      p :q => q
      q.logger = _logger
    end
  end # def logger=

  # Push an object to all queues.
  public
  def push(object)
    @metric_queue_write.time do
      @queues.each { |q| q.push(object) }
    end
  end # def push
  alias :<< :push

  alias_method :<<, :push

  # Add a new Queue to this queue.
  public
  def add_queue(queue)
    @mutex.synchronize do
      @metric_queue_count.incr
      @queues << queue
    end
  end # def add_queue

  public
  def remove_queue(queue)
    @mutex.synchronize do
      @metric_queue_count.decr
      @queues.delete(queue)
    end
  end # def remove_queue

  public
  def size
    return @queues.collect { |q| q.size }
  end # def size
end # class LogStash::MultiQueue
