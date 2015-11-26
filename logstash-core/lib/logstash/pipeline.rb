# encoding: utf-8
require "thread"
require "stud/interval"
require "concurrent"
require "logstash/namespace"
require "logstash/errors"
require "logstash/event"
require "logstash/config/file"
require "logstash/filters/base"
require "logstash/inputs/base"
require "logstash/outputs/base"
require "logstash/config/cpu_core_strategy"
require "logstash/util/defaults_printer"
require "logstash/shutdown_controller"
require "logstash/util/wrapped_synchronous_queue"
require "logstash/pipeline_reporter"
require "logstash/instrument/metric"
require "logstash/instrument/null_metric"
require "logstash/instrument/collector"

module LogStash; class Pipeline
  attr_reader :inputs, :filters, :outputs, :worker_threads, :events_consumed, :events_filtered, :reporter, :pipeline_id, :metric

  def initialize(config_str, settings = {})
    @pipeline_id = settings[:pipeline_id] || self.object_id
    @logger = Cabin::Channel.get(LogStash)
    @reporter = LogStash::PipelineReporter.new(@logger, self)

    @inputs = nil
    @filters = nil
    @outputs = nil

    @worker_threads = []

    # Metric object should be passed upstream, multiple pipeline share the same metric
    # and collector only the namespace will changes.
    # If no metric is given, we use a `NullMetric` for all internal calls.
    #
    # This need to be configured before we evaluate the code to make
    # sure the metric instance is correctly send to the plugin.
    @metric = settings.fetch(:metric, Instrument::NullMetric.new)

    grammar = LogStashConfigParser.new
    @config = grammar.parse(config_str)
    if @config.nil?
      raise LogStash::ConfigurationError, grammar.failure_reason
    end
    # This will compile the config to ruby and evaluate the resulting code.
    # The code will initialize all the plugins and define the
    # filter and output methods.
    code = @config.compile
    # The config code is hard to represent as a log message...
    # So just print it.
    @logger.debug? && @logger.debug("Compiled pipeline code:\n#{code}")
    begin
      eval(code)
    rescue => e
      raise
    end

    @input_queue = LogStash::Util::WrappedSynchronousQueue.new
    @events_filtered = Concurrent::AtomicFixnum.new(0)
    @events_consumed = Concurrent::AtomicFixnum.new(0)

    # We generally only want one thread at a time able to access pop/take/poll operations
    # from this queue. We also depend on this to be able to block consumers while we snapshot
    # in-flight buffers
    @input_queue_pop_mutex = Mutex.new

    @input_threads = []

    @settings = {
      # We don't set pipeline workers defaults here, but rather in safe_pipeline_workers
      :pipeline_batch_size => 125,
      :pipeline_batch_delay => 50 # in milliseconds
    }

    # @ready requires thread safety since it is typically polled from outside the pipeline thread
    @ready = Concurrent::AtomicBoolean.new(false)
    @input_threads = []
    settings.each {|setting, value| configure(setting, value) }
  end # def initialize

  def ready?
    @ready.value
  end

  def configure(setting, value)
    @settings[setting] = value
  end

  def safe_pipeline_worker_count
    default = LogStash::Config::CpuCoreStrategy.fifty_percent
    thread_count = @settings[:pipeline_workers] #override from args "-w 8" or config
    safe_filters, unsafe_filters = @filters.partition(&:threadsafe?)

    if unsafe_filters.any?
      plugins = unsafe_filters.collect { |f| f.class.config_name }
      case thread_count
        when nil
          # user did not specify a worker thread count
          # warn if the default is multiple
          @logger.warn("Defaulting pipeline worker threads to 1 because there are some filters that might not work with multiple worker threads",
                       :count_was => default, :filters => plugins) if default > 1
          1 # can't allow the default value to propagate if there are unsafe filters
        when 0, 1
          1
        else
          @logger.warn("Warning: Manual override - there are filters that might not work with multiple worker threads",
                       :worker_threads => thread_count, :filters => plugins)
          thread_count # allow user to force this even if there are unsafe filters
      end
    else
      thread_count || default
    end
  end

  def filters?
    return @filters.any?
  end

  def run
    LogStash::Util.set_thread_name("[#{pipeline_id}]-pipeline-manager")
    @logger.terminal(LogStash::Util::DefaultsPrinter.print(@settings))

    start_workers

    @logger.info("Pipeline started")
    @logger.terminal("Logstash startup completed")

    @logger.info("Will run till input threads stopped")

    # Block until all inputs have stopped
    # Generally this happens if SIGINT is sent and `shutdown` is called from an external thread
    wait_inputs
    @logger.info("Inputs stopped")

    shutdown_workers

    @logger.info("Pipeline shutdown complete.")
    @logger.terminal("Logstash shutdown completed")

    # exit code
    return 0
  end # def run

  def start_workers
    @inflight_batches = {}

    @worker_threads.clear # In case we're restarting the pipeline
    begin
      start_inputs
      @outputs.each {|o| o.register }
      @filters.each {|f| f.register}

      pipeline_workers = safe_pipeline_worker_count
      batch_size = @settings[:pipeline_batch_size]
      batch_delay = @settings[:pipeline_batch_delay]
      @logger.info("Starting pipeline",
                   :id => self.pipeline_id,
                   :pipeline_workers => pipeline_workers,
                   :batch_size => batch_size,
                   :batch_delay => batch_delay)

      pipeline_workers.times do |t|
        @worker_threads << Thread.new do
          LogStash::Util.set_thread_name("[#{pipeline_id}]>worker#{t}")
          worker_loop(batch_size, batch_delay)
        end
      end
    ensure
      # it is important to garantee @ready to be true after the startup sequence has been completed
      # to potentially unblock the shutdown method which may be waiting on @ready to proceed
      @ready.make_true
    end
  end

  # Main body of what a worker threda does
  # Repeatedly takes batches off the queu, filters, then outputs them
  def worker_loop(batch_size, batch_delay)
    running = true

    while running
      # To understand the purpose behind this synchronize please read the body of take_batch
      input_batch, shutdown_received = @input_queue_pop_mutex.synchronize { take_batch(batch_size, batch_delay) }
      running = false if shutdown_received

      metric.increment(:events_in, input_batch.size)
      @events_consumed.increment(input_batch.size)

      filtered = filter_batch(input_batch)

      @events_filtered.increment(filtered.size)
      @metric.increment(:events_filtered, filtered.size)

      output_batch(filtered)

      inflight_batches_synchronize { set_current_thread_inflight_batch(nil) }
    end
  end

  def take_batch(batch_size, batch_delay)
    batch = []
    # Since this is externally synchronized in `worker_loop` we can guarantee that the visibility of an insight batch
    # guaranteed to be a full batch not a partial batch
    set_current_thread_inflight_batch(batch)

    shutdown_received = false
    batch_size.times do |t|
      event = t==0 ? @input_queue.take : @input_queue.poll(batch_delay)
      # Exit early so each thread only gets one copy of this
      # This is necessary to ensure proper shutdown!
      next if event.nil?

      if event == LogStash::SHUTDOWN
        shutdown_received = true
        break
      end

      batch << event
    end

    [batch, shutdown_received]
  end

  def filter_batch(batch)
    batch.reduce([]) do |acc,e|
      if e.is_a?(LogStash::Event)
        filtered = filter_func(e)
        filtered.each {|fe| acc << fe unless fe.cancelled?}
      end
      acc
    end
  rescue Exception => e
    # Plugins authors should manage their own exceptions in the plugin code
    # but if an exception is raised up to the worker thread they are considered
    # fatal and logstash will not recover from this situation.
    #
    # Users need to check their configuration or see if there is a bug in the
    # plugin.
    @logger.error("Exception in pipelineworker, the pipeline stopped processing new events, please check your filter configuration and restart Logstash.",
                  "exception" => e, "backtrace" => e.backtrace)
    raise
  end

  # Take an array of events and send them to the correct output
  def output_batch(batch)
    batch.reduce(Hash.new { |h, k| h[k] = [] }) do |outputs_events, event|
      # We ask the AST to tell us which outputs to send each event to
      output_func(event).each do |output|
        outputs_events[output] << event
      end
      outputs_events
    end.each do |output, events|
      # Once we have a mapping of outputs => [events] we can execute them
      output.multi_handle(events)
    end
  end

  def set_current_thread_inflight_batch(batch)
    @inflight_batches[Thread.current] = batch
  end

  def inflight_batches_synchronize
    @input_queue_pop_mutex.synchronize do
      yield(@inflight_batches)
    end
  end

  def dump_inflight(file_path)
    inflight_batches_synchronize do |batches|
      File.open(file_path, "w") do |f|
        batches.values.each do |batch|
          next unless batch
          batch.each do |e|
            f.write(LogStash::Json.dump(e))
          end
        end
      end
    end
  end

  def wait_inputs
    @input_threads.each(&:join)
  end

  def start_inputs
    moreinputs = []
    @inputs.each do |input|
      if input.threadable && input.threads > 1
        (input.threads - 1).times do |i|
          moreinputs << input.clone
        end
      end
    end
    @inputs += moreinputs

    @inputs.each do |input|
      input.register
      start_input(input)
    end
  end

  def start_input(plugin)
    @input_threads << Thread.new { inputworker(plugin) }
  end

  def inputworker(plugin)
    LogStash::Util::set_thread_name("[#{pipeline_id}]<#{plugin.class.config_name}")
    begin
      plugin.run(@input_queue)
    rescue => e
      # if plugin is stop
      if plugin.stop?
        @logger.debug("Input plugin raised exception during shutdown, ignoring it.",
                      :plugin => plugin.class.config_name, :exception => e,
                      :backtrace => e.backtrace)
        return
      end

      # otherwise, report error and restart
      if @logger.debug?
        @logger.error(I18n.t("logstash.pipeline.worker-error-debug",
                             :plugin => plugin.inspect, :error => e.to_s,
                             :exception => e.class,
                             :stacktrace => e.backtrace.join("\n")))
      else
        @logger.error(I18n.t("logstash.pipeline.worker-error",
                             :plugin => plugin.inspect, :error => e))
      end

      # Assuming the failure that caused this exception is transient,
      # let's sleep for a bit and execute #run again
      sleep(1)
      retry
    ensure
      plugin.do_close
    end
  end # def inputworker

  # initiate the pipeline shutdown sequence
  # this method is intended to be called from outside the pipeline thread
  # @param before_stop [Proc] code block called before performing stop operation on input plugins
  def shutdown(&before_stop)
    # shutdown can only start once the pipeline has completed its startup.
    # avoid potential race conditoon between the startup sequence and this
    # shutdown method which can be called from another thread at any time
    sleep(0.1) while !ready?

    # TODO: should we also check against calling shutdown multiple times concurently?

    before_stop.call if block_given?

    @logger.info "Closing inputs"
    @inputs.each(&:do_stop)
    @logger.info "Closed inputs"
  end # def shutdown

  # After `shutdown` is called from an external thread this is called from the main thread to
  # tell the worker threads to stop and then block until they've fully stopped
  # This also stops all filter and output plugins
  def shutdown_workers
    # Each worker thread will receive this exactly once!
    @worker_threads.each do |t|
      @logger.debug("Pushing shutdown", :thread => t)
      @input_queue.push(LogStash::SHUTDOWN)
    end

    @worker_threads.each do |t|
      @logger.debug("Shutdown waiting for worker thread #{t}")
      t.join
    end

    @filters.each(&:do_close)
    @outputs.each(&:do_close)
  end

  def plugin(plugin_type, name, *args)
    args << {} if args.empty?
    klass = LogStash::Plugin.lookup(plugin_type, name)

    # Backward compatible way of adding code to 
    plugin = klass.new(*args)
    plugin.metric = metric
    plugin
  end

  # for backward compatibility in devutils for the rspec helpers, this method is not used
  # in the pipeline anymore.
  def filter(event, &block)
    # filter_func returns all filtered events, including cancelled ones
    filter_func(event).each { |e| block.call(e) }
  end


  # perform filters flush and yeild flushed event to the passed block
  # @param options [Hash]
  # @option options [Boolean] :final => true to signal a final shutdown flush
  def flush_filters(options = {}, &block)
    flushers = options[:final] ? @shutdown_flushers : @periodic_flushers

    flushers.each do |flusher|
      flusher.call(options, &block)
    end
  end

  def plugin_threads_info
    input_threads = @input_threads.select {|t| t.alive? }
    worker_threads = @worker_threads.select {|t| t.alive? }
    (input_threads + worker_threads).map {|t| LogStash::Util.thread_info(t) }
  end

  def stalling_threads_info
    plugin_threads_info
      .reject {|t| t["blocked_on"] } # known benign blocking statuses
      .each {|t| t.delete("backtrace") }
      .each {|t| t.delete("blocked_on") }
      .each {|t| t.delete("status") }
  end
end end
