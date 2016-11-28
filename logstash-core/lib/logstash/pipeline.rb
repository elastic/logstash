# encoding: utf-8
require "thread"
require "stud/interval"
require "concurrent"
require "logstash/namespace"
require "logstash/errors"
require "logstash-core/logstash-core"
require "logstash/util/wrapped_acked_queue"
require "logstash/util/wrapped_synchronous_queue"
require "logstash/event"
require "logstash/config/file"
require "logstash/filters/base"
require "logstash/inputs/base"
require "logstash/outputs/base"
require "logstash/shutdown_watcher"
require "logstash/pipeline_reporter"
require "logstash/instrument/metric"
require "logstash/instrument/namespaced_metric"
require "logstash/instrument/null_metric"
require "logstash/instrument/namespaced_null_metric"
require "logstash/instrument/collector"
require "logstash/output_delegator"
require "logstash/filter_delegator"

module LogStash; class Pipeline
  include LogStash::Util::Loggable

  attr_reader :inputs,
    :filters,
    :outputs,
    :worker_threads,
    :events_consumed,
    :events_filtered,
    :reporter,
    :pipeline_id,
    :started_at,
    :thread,
    :config_str,
    :config_hash,
    :settings,
    :metric,
    :filter_queue_client,
    :input_queue_client

  MAX_INFLIGHT_WARN_THRESHOLD = 10_000

  RELOAD_INCOMPATIBLE_PLUGINS = [
    "LogStash::Inputs::Stdin"
  ]

  def initialize(config_str, settings = SETTINGS, namespaced_metric = nil)
    @logger = self.logger
    @config_str = config_str
    @config_hash = Digest::SHA1.hexdigest(@config_str)
    # Every time #plugin is invoked this is incremented to give each plugin
    # a unique id when auto-generating plugin ids
    @plugin_counter ||= 0
    @settings = settings
    @pipeline_id = @settings.get_value("pipeline.id") || self.object_id
    @reporter = PipelineReporter.new(@logger, self)

    # A list of plugins indexed by id
    @plugins_by_id = {}
    @inputs = nil
    @filters = nil
    @outputs = nil

    @worker_threads = []

    # This needs to be configured before we evaluate the code to make
    # sure the metric instance is correctly send to the plugins to make the namespace scoping work
    @metric = namespaced_metric.nil? ? Instrument::NullMetric.new : namespaced_metric

    grammar = LogStashConfigParser.new
    @config = grammar.parse(config_str)
    if @config.nil?
      raise ConfigurationError, grammar.failure_reason
    end
    # This will compile the config to ruby and evaluate the resulting code.
    # The code will initialize all the plugins and define the
    # filter and output methods.
    code = @config.compile
    @code = code

    # The config code is hard to represent as a log message...
    # So just print it.

    if @settings.get_value("config.debug") && @logger.debug?
      @logger.debug("Compiled pipeline code", :code => code)
    end

    begin
      eval(code)
    rescue => e
      raise
    end
    @queue = build_queue_from_settings
    @input_queue_client = @queue.write_client
    @filter_queue_client = @queue.read_client
    @signal_queue = Queue.new
    # Note that @infilght_batches as a central mechanism for tracking inflight
    # batches will fail if we have multiple read clients here.
    @filter_queue_client.set_events_metric(metric.namespace([:stats, :events]))
    @filter_queue_client.set_pipeline_metric(
        metric.namespace([:stats, :pipelines, pipeline_id.to_s.to_sym, :events])
    )

    @events_filtered = Concurrent::AtomicFixnum.new(0)
    @events_consumed = Concurrent::AtomicFixnum.new(0)

    @input_threads = []
    # @ready requires thread safety since it is typically polled from outside the pipeline thread
    @ready = Concurrent::AtomicBoolean.new(false)
    @running = Concurrent::AtomicBoolean.new(false)
    @flushing = Concurrent::AtomicReference.new(false)
  end # def initialize

  def build_queue_from_settings
    queue_type = settings.get("queue.type")
    queue_page_capacity = settings.get("queue.page_capacity")
    queue_max_bytes = settings.get("queue.max_bytes")
    queue_max_events = settings.get("queue.max_events")
    checkpoint_max_acks = settings.get("queue.checkpoint.acks")
    checkpoint_max_writes = settings.get("queue.checkpoint.writes")
    checkpoint_max_interval = settings.get("queue.checkpoint.interval")

    if queue_type == "memory_acked"
      # memory_acked is used in tests/specs
      LogStash::Util::WrappedAckedQueue.create_memory_based("", queue_page_capacity, queue_max_events, queue_max_bytes)
    elsif queue_type == "memory"
      # memory is the legacy and default setting
      LogStash::Util::WrappedSynchronousQueue.new()
    elsif queue_type == "persisted"
      # persisted is the disk based acked queue
      queue_path = settings.get("path.queue")
      LogStash::Util::WrappedAckedQueue.create_file_based(queue_path, queue_page_capacity, queue_max_events, checkpoint_max_writes, checkpoint_max_acks, checkpoint_max_interval, queue_max_bytes)
    else
      raise(ConfigurationError, "invalid queue.type setting")
    end
  end

  private :build_queue_from_settings

  def ready?
    @ready.value
  end

  def safe_pipeline_worker_count
    default = @settings.get_default("pipeline.workers")
    pipeline_workers = @settings.get("pipeline.workers") #override from args "-w 8" or config
    safe_filters, unsafe_filters = @filters.partition(&:threadsafe?)
    plugins = unsafe_filters.collect { |f| f.config_name }

    return pipeline_workers if unsafe_filters.empty?

    if @settings.set?("pipeline.workers")
      if pipeline_workers > 1
        @logger.warn("Warning: Manual override - there are filters that might not work with multiple worker threads",
                     :worker_threads => pipeline_workers, :filters => plugins)
      end
    else
      # user did not specify a worker thread count
      # warn if the default is multiple
      if default > 1
        @logger.warn("Defaulting pipeline worker threads to 1 because there are some filters that might not work with multiple worker threads",
                     :count_was => default, :filters => plugins)
        return 1 # can't allow the default value to propagate if there are unsafe filters
      end
    end
    pipeline_workers
  end

  def filters?
    return @filters.any?
  end

  def run
    @started_at = Time.now

    @thread = Thread.current
    Util.set_thread_name("[#{pipeline_id}]-pipeline-manager")

    start_workers

    @logger.info("Pipeline #{@pipeline_id} started")

    # Block until all inputs have stopped
    # Generally this happens if SIGINT is sent and `shutdown` is called from an external thread

    transition_to_running
    start_flusher # Launches a non-blocking thread for flush events
    wait_inputs
    transition_to_stopped

    @logger.debug("Input plugins stopped! Will shutdown filter/output workers.")

    shutdown_flusher
    shutdown_workers

    @filter_queue_client.close
    @queue.close

    @logger.debug("Pipeline #{@pipeline_id} has been shutdown")

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
    @worker_threads.clear # In case we're restarting the pipeline
    begin
      start_inputs
      @outputs.each {|o| o.register }
      @filters.each {|f| f.register }

      pipeline_workers = safe_pipeline_worker_count
      batch_size = @settings.get("pipeline.batch.size")
      batch_delay = @settings.get("pipeline.batch.delay")

      max_inflight = batch_size * pipeline_workers

      config_metric = metric.namespace([:stats, :pipelines, pipeline_id.to_s.to_sym, :config])
      config_metric.gauge(:workers, pipeline_workers)
      config_metric.gauge(:batch_size, batch_size)
      config_metric.gauge(:batch_delay, batch_delay)
      config_metric.gauge(:config_reload_automatic, @settings.get("config.reload.automatic"))
      config_metric.gauge(:config_reload_interval, @settings.get("config.reload.interval"))

      @logger.info("Starting pipeline",
                   "id" => self.pipeline_id,
                   "pipeline.workers" => pipeline_workers,
                   "pipeline.batch.size" => batch_size,
                   "pipeline.batch.delay" => batch_delay,
                   "pipeline.max_inflight" => max_inflight)
      if max_inflight > MAX_INFLIGHT_WARN_THRESHOLD
        @logger.warn "CAUTION: Recommended inflight events max exceeded! Logstash will run with up to #{max_inflight} events in memory in your current configuration. If your message sizes are large this may cause instability with the default heap size. Please consider setting a non-standard heap size, changing the batch size (currently #{batch_size}), or changing the number of pipeline workers (currently #{pipeline_workers})"
      end

      pipeline_workers.times do |t|
        @worker_threads << Thread.new do
          Util.set_thread_name("[#{pipeline_id}]>worker#{t}")
          worker_loop(batch_size, batch_delay)
        end
      end
    ensure
      # it is important to guarantee @ready to be true after the startup sequence has been completed
      # to potentially unblock the shutdown method which may be waiting on @ready to proceed
      @ready.make_true
    end
  end

  # Main body of what a worker thread does
  # Repeatedly takes batches off the queue, filters, then outputs them
  def worker_loop(batch_size, batch_delay)
    running = true

    @filter_queue_client.set_batch_dimensions(batch_size, batch_delay)

    while running
      batch = @filter_queue_client.take_batch
      signal = @signal_queue.empty? ? NO_SIGNAL : @signal_queue.pop
      running = !signal.shutdown?

      @events_consumed.increment(batch.size)

      filter_batch(batch)

      if signal.flush? || signal.shutdown?
        flush_filters_to_batch(batch, :final => signal.shutdown?)
      end

      output_batch(batch)
      @filter_queue_client.close_batch(batch)
    end
  end

  def filter_batch(batch)
    batch.each do |event|
      filter_func(event).each do |e|
        #these are both original and generated events
        batch.merge(e) unless e.cancelled?
      end
    end
    @filter_queue_client.add_filtered_metrics(batch)
    @events_filtered.increment(batch.size)
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
    output_events_map = Hash.new { |h, k| h[k] = [] }
    batch.each do |event|
      # We ask the AST to tell us which outputs to send each event to
      # Then, we stick it in the correct bin

      # output_func should never return anything other than an Array but we have lots of legacy specs
      # that monkeypatch it and return nil. We can deprecate  "|| []" after fixing these specs
      (output_func(event) || []).each do |output|
        output_events_map[output].push(event)
      end
    end
    # Now that we have our output to event mapping we can just invoke each output
    # once with its list of events
    output_events_map.each do |output, events|
      output.multi_receive(events)
    end
    
    @filter_queue_client.add_output_metrics(batch)
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
    Util::set_thread_name("[#{pipeline_id}]<#{plugin.class.config_name}")
    begin
      plugin.run(@input_queue_client)
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

    @logger.debug "Closing inputs"
    @inputs.each(&:do_stop)
    @logger.debug "Closed inputs"
  end # def shutdown

  # After `shutdown` is called from an external thread this is called from the main thread to
  # tell the worker threads to stop and then block until they've fully stopped
  # This also stops all filter and output plugins
  def shutdown_workers
    # Each worker thread will receive this exactly once!
    @worker_threads.each do |t|
      @logger.debug("Pushing shutdown", :thread => t.inspect)
      @signal_queue.push(SHUTDOWN)
    end

    @worker_threads.each do |t|
      @logger.debug("Shutdown waiting for worker thread #{t}")
      t.join
    end

    @filters.each(&:do_close)
    @outputs.each(&:do_close)
  end

  def plugin(plugin_type, name, *args)
    @plugin_counter += 1

    # Collapse the array of arguments into a single merged hash
    args = args.reduce({}, &:merge)

    id = if args["id"].nil? || args["id"].empty?
           args["id"] = "#{@config_hash}-#{@plugin_counter}"
         else
           args["id"]
         end

    raise ConfigurationError, "Two plugins have the id '#{id}', please fix this conflict" if @plugins_by_id[id]
    
    pipeline_scoped_metric = metric.namespace([:stats, :pipelines, pipeline_id.to_s.to_sym, :plugins])

    klass = Plugin.lookup(plugin_type, name)

    # Scope plugins of type 'input' to 'inputs'
    type_scoped_metric = pipeline_scoped_metric.namespace("#{plugin_type}s".to_sym)
    plugin = if plugin_type == "output"
               OutputDelegator.new(@logger, klass, type_scoped_metric,
                                   OutputDelegatorStrategyRegistry.instance,
                                   args)
             elsif plugin_type == "filter"
               FilterDelegator.new(@logger, klass, type_scoped_metric, args)
             else # input
               input_plugin = klass.new(args)
               input_plugin.metric = type_scoped_metric.namespace(id)
               input_plugin
             end
    
    @plugins_by_id[id] = plugin
  end

  # for backward compatibility in devutils for the rspec helpers, this method is not used
  # in the pipeline anymore.
  def filter(event, &block)
    # filter_func returns all filtered events, including cancelled ones
    filter_func(event).each { |e| block.call(e) }
  end


  # perform filters flush and yield flushed event to the passed block
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
      @signal_queue.push(FLUSH)
    end
  end


  # Calculate the uptime in milliseconds
  #
  # @return [Fixnum] Uptime in milliseconds, 0 if the pipeline is not started
  def uptime
    return 0 if started_at.nil?
    ((Time.now.to_f - started_at.to_f) * 1000.0).to_i
  end

  # perform filters flush into the output queue
  #
  # @param batch [ReadClient::ReadBatch]
  # @param options [Hash]
  def flush_filters_to_batch(batch, options = {})
    flush_filters(options) do |event|
      unless event.cancelled?
        @logger.debug? and @logger.debug("Pushing flushed events", :event => event)
        batch.merge(event)
      end
    end

    @flushing.set(false)
  end # flush_filters_to_batch

  def plugin_threads_info
    input_threads = @input_threads.select {|t| t.alive? }
    worker_threads = @worker_threads.select {|t| t.alive? }
    (input_threads + worker_threads).map {|t| Util.thread_info(t) }
  end

  def stalling_threads_info
    plugin_threads_info
      .reject {|t| t["blocked_on"] } # known benign blocking statuses
      .each {|t| t.delete("backtrace") }
      .each {|t| t.delete("blocked_on") }
      .each {|t| t.delete("status") }
  end

  def non_reloadable_plugins
    (inputs + filters + outputs).select do |plugin|
      RELOAD_INCOMPATIBLE_PLUGINS.include?(plugin.class.name)
    end
  end

  # Sometimes we log stuff that will dump the pipeline which may contain
  # sensitive information (like the raw syntax tree which can contain passwords)
  # We want to hide most of what's in here
  def inspect
    {
      :pipeline_id => @pipeline_id,
      :settings => @settings.inspect,
      :ready => @ready,
      :running => @running,
      :flushing => @flushing
    }
  end

end end
