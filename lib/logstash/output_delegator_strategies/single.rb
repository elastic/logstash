module LogStash module OutputDelegatorStrategies class Single
  def initialize(logger, klass, metric, plugin_args)
    @output = klass.new(plugin_args)
    @output.metric = metric
    @mutex = Mutex.new
  end

  def register
    @output.register
  end
  
  def multi_receive(events)
    @mutex.synchronize do
      @output.multi_receive(events)
    end
  end

  def do_close
    # No mutex needed since this is only called when the pipeline is clear
    @output.do_close
  end

  ::LogStash::OutputDelegatorStrategyRegistry.instance.register(:single, self)
end; end; end
