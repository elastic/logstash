require "logstash/namespace"
require "logstash/logging"

class LogStash::MultiQueue
  public
  def initialize(*queues)
    @logger = LogStash::Logger.new(STDOUT)
    @mutex = Mutex.new
    @queues = queues
  end # def initialize

  # Push an object to all queues.
  public
  def push(object)
    @logger.info "*** Pushing object into MultiQueue: #{object}"
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
  def size
    return @queues.collect { |q| q.size }
  end # def size
end
