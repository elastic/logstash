class MultiQueue
  public
  def initialize(*queues)
    @mutex = Mutex.new
    @queues = queues
  end

  # Push an object to all queues.
  public
  def push(object)
    @queues.each { |q| q.push(object) }
  end

  alias_method :<<, :push

  # Add a new Queue to this queue.
  public
  def add_queue(queue)
    @mutex.synchronize do
      @queues << queue
    end
  end
end
