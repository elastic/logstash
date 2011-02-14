class MultiQueue
  def initialize(*queues)
    @mutex = Mutex.new
    @queues = queues
  end

  def push(object)
    @queues.each { |q| q.push(object) }
  end

  public
  def add_queue(queue)
    @mutex.synchronize do
      @queues << queue
    end
  end
end
