# Remove this in Logstash 6.0
module LogStash module OutputDelegatorStrategies class Legacy
  attr_reader :worker_count, :workers
  
  def initialize(logger, klass, metric, execution_context, plugin_args)
    @worker_count = (plugin_args["workers"] || 1).to_i
    @workers = @worker_count.times.map { klass.new(plugin_args) }
    @workers.each do |w|
      w.metric = metric
      w.execution_context = execution_context
    end
    @worker_queue = SizedQueue.new(@worker_count)
    @workers.each {|w| @worker_queue << w}
  end
  
  def register
    @workers.each(&:register)
  end
  
  def multi_receive(events)
    worker = @worker_queue.pop
    worker.multi_receive(events)
  ensure
    @worker_queue << worker if worker
  end

  def do_close
    # No mutex needed since this is only called when the pipeline is clear
    @workers.each(&:do_close)
  end

  ::LogStash::OutputDelegatorStrategyRegistry.instance.register(:legacy, self)
end; end; end
