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
require "logstash/shutdown_watcher"
require "logstash/util/wrapped_synchronous_queue"
require "logstash/pipeline_reporter"
require "logstash/output_delegator"

module LogStash; class Pipeline
  attr_reader :inputs, :filters, :outputs, :worker_threads, :events_consumed, :events_filtered, :reporter, :pipeline_id, :logger

  DEFAULT_SETTINGS = {
    :default_pipeline_workers => LogStash::Config::CpuCoreStrategy.maximum,
    :pipeline_batch_size => 125,
    :pipeline_batch_delay => 5, # in milliseconds
    :flush_interval => 5, # in seconds
    :flush_timeout_interval => 60 # in seconds
  }
  MAX_INFLIGHT_WARN_THRESHOLD = 10_000

  def initialize(config_str, settings = {})
    @pipeline_id = settings[:pipeline_id] || self.object_id
    @logger = Cabin::Channel.get(LogStash)
    @settings = DEFAULT_SETTINGS.clone
    settings.each {|setting, value| configure(setting, value) }
    @reporter = LogStash::PipelineReporter.new(@logger, self)

    @inputs = nil
    @filters = nil
    @outputs = nil

    @worker_threads = []

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
    # @ready requires thread safety since it is typically polled from outside the pipeline thread
    @ready = Concurrent::AtomicBoolean.new(false)
    @running = Concurrent::AtomicBoolean.new(false)
    @flushing = Concurrent::AtomicReference.new(false)
  end # def initialize

  def ready?
    @ready.value
  end

  def configure(setting, value)
    @settings[setting] = value
  end

  def safe_pipeline_worker_count
    default = DEFAULT_SETTINGS[:default_pipeline_workers]
    thread_count = @settings[:pipeline_workers] #override from args "-w 8" or config
    safe_filters, unsafe_filters = @filters.partition(&:threadsafe?)

    if unsafe_filters.any?
      plugins = unsafe_filters.collect { |f| f.class.config_name }
      case thread_count
      when nil
        # user did not specify a worker thread count
        # warn if the default is multiple

        if default > 1
          @logger.warn("Defaulting pipeline worker threads to 1 because there are some filters that might not work with multiple worker threads",
                       :count_was => default, :filters => plugins)
        end

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

    # Block until all inputs have stopped
    # Generally this happens if SIGINT is sent and `shutdown` is called from an external thread

    transition_to_running
    start_flusher # Launches a non-blocking thread for flush events
    wait_inputs
    transition_to_stopped

    @logger.info("Input plugins stopped! Will shutdown filter/output workers.")

    shutdown_flusher
    shutdown_workers

    @logger.info("Pipeline shutdown complete.")
    @logger.terminal("Logstash shutdown completed")

    # exit code
    return 0
  end # def run

  def transition_to_running
    @running.make_true
  end

  def transition_to_stopped
    @running.make_false
  end

  def running?
    @running.true?
  end

  def stopped?
    @running.false?
  end

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
      max_inflight = batch_size * pipeline_workers
      @logger.info("Starting pipeline",
                   :id => self.pipeline_id,
                   :pipeline_workers => pipeline_workers,
                   :batch_size => batch_size,
                   :batch_delay => batch_delay,
                   :max_inflight => max_inflight)
      if max_inflight > MAX_INFLIGHT_WARN_THRESHOLD
        @logger.warn "CAUTION: Recommended inflight events max exceeded! Logstash will run with up to #{max_inflight} events in memory in your current configuration. If your message sizes are large this may cause instability with the default heap size. Please consider setting a non-standard heap size, changing the batch size (currently #{batch_size}), or changing the number of pipeline workers (currently #{pipeline_workers})"
      end

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

  # Main body of what a worker thread does
  # Repeatedly takes batches off the queu, filters, then outputs them
  def worker_loop(batch_size, batch_delay)
    running = true

    while running
      # To understand the purpose behind this synchronize please read the body of take_batch
      input_batch, signal = @input_queue_pop_mutex.synchronize { take_batch(batch_size, batch_delay) }
      running = false if signal == LogStash::SHUTDOWN

      @events_consumed.increment(input_batch.size)

      filtered_batch = filter_batch(input_batch)

      if signal # Flush on SHUTDOWN or FLUSH
        flush_options = (signal == LogStash::SHUTDOWN) ? {:final => true} : {}
        flush_filters_to_batch(filtered_batch, flush_options)
      end

      @events_filtered.increment(filtered_batch.size)

      output_batch(filtered_batch)

      inflight_batches_synchronize { set_current_thread_inflight_batch(nil) }
    end
  end

  def take_batch(batch_size, batch_delay)
    batch = []
    # Since this is externally synchronized in `worker_look` wec can guarantee that the visibility of an insight batch
    # guaranteed to be a full batch not a partial batch
    set_current_thread_inflight_batch(batch)

    signal = false
    batch_size.times do |t|
      event = (t == 0) ? @input_queue.take : @input_queue.poll(batch_delay)

      if event.nil?
        next
      elsif event == LogStash::SHUTDOWN || event == LogStash::FLUSH
        # We MUST break here. If a batch consumes two SHUTDOWN events
        # then another worker may have its SHUTDOWN 'stolen', thus blocking
        # the pipeline. We should stop doing work after flush as well.
        signal = event
        break
      else
        batch << event
      end
    end

    [batch, signal]
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
    # Build a mapping of { output_plugin => [events...]}
    outputs_events = batch.reduce(Hash.new { |h, k| h[k] = [] }) do |acc, event|
      # We ask the AST to tell us which outputs to send each event to
      # Then, we stick it in the correct bin

      # output_func should never return anything other than an Array but we have lots of legacy specs
      # that monkeypatch it and return nil. We can deprecate  "|| []" after fixing these specs
      outputs_for_event = output_func(event) || []

      outputs_for_event.each { |output| acc[output] << event }
      acc
    end

    # Now that we have our output to event mapping we can just invoke each output
    # once with its list of events
    outputs_events.each { |output, events| output.multi_receive(events) }
  end

  def set_current_thread_inflight_batch(batch)
    @inflight_batches[Thread.current] = batch
  end

  def inflight_batches_synchronize
    @input_queue_pop_mutex.synchronize do
      yield(@inflight_batches)
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

    if plugin_type == "output"
      LogStash::OutputDelegator.new(@logger, klass, default_output_workers, *args)
    else
      klass.new(*args)
    end
  end

  def default_output_workers
    @settings[:pipeline_workers] || @settings[:default_pipeline_workers]
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

  def start_flusher
    # Invariant to help detect improper initialization
    raise "Attempted to start flusher on a stopped pipeline!" if stopped?

    @flusher_thread = Thread.new do
      while Stud.stoppable_sleep(5, 0.1) { stopped? }
        flush
        break if stopped?
      end
    end
  end

  def shutdown_flusher
    @flusher_thread.join
  end

  def flush
    if @flushing.compare_and_set(false, true)
      @logger.debug? && @logger.debug("Pushing flush onto pipeline")
      @input_queue.push(LogStash::FLUSH)
    end
  end

  # perform filters flush into the output queue
  # @param options [Hash]
  # @option options [Boolean] :final => true to signal a final shutdown flush
  def flush_filters_to_batch(batch, options = {})
    flush_filters(options) do |event|
      unless event.cancelled?
        @logger.debug? and @logger.debug("Pushing flushed events", :event => event)
        batch << event
      end
    end

    @flushing.set(false)
  end # flush_filters_to_output!

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
