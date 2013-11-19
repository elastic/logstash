# encoding: utf-8
require "logstash/namespace"
require "cabin"

class LogStash::MultiQueue
  attr_accessor :logger

  public
  def initialize(*queues)
    @logger = Cabin::Channel.get(LogStash)
    @mutex = Mutex.new
    @queues = queues
  end # def initialize

  public
  def logger=(_logger)
    @logger = _logger

    # Set the logger for all known queues, too.
    @queues.each do |q|
      q.logger = _logger
    end
  end # def logger=

  # Push an object to all queues.
  public
  def push(object)
    @queues.each { |q| q.push(object) }
  end # def push
  alias :<< :push

  alias_method :<<, :push

  # Add a new Queue to this queue.
  public
  def add_queue(queue)
    @mutex.synchronize do
      @queues << queue
    end
  end # def add_queue

  public
  def remove_queue(queue)
    @mutex.synchronize do
      @queues.delete(queue)
    end
  end # def remove_queue

  public
  def size
    return @queues.collect { |q| q.size }
  end # def size
end # class LogStash::MultiQueue
