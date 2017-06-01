# encoding: utf-8
require "thread"
require "stud/interval"
require "concurrent"
require "logstash/namespace"
require "logstash/errors"
require "logstash-core/logstash-core"
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
require "logstash/instrument/wrapped_write_client"
require "logstash/util/dead_letter_queue_manager"
require "logstash/output_delegator"
require "logstash/filter_delegator"
require "logstash/queue_factory"
require "logstash/compiler"
require "logstash/execution_context"

java_import org.logstash.common.DeadLetterQueueFactory
java_import org.logstash.common.io.DeadLetterQueueWriter

module LogStash; class BasePipeline
  include LogStash::Util::Loggable

  attr_reader :settings, :config_str, :config_hash, :inputs, :filters, :outputs, :pipeline_id, :lir, :execution_context
  attr_reader :pipeline_config

  def initialize(pipeline_config, namespaced_metric = nil, agent = nil)
    @logger = self.logger

    @pipeline_config = pipeline_config
    @config_str = pipeline_config.config_string
    @settings = pipeline_config.settings
    @config_hash = Digest::SHA1.hexdigest(@config_str)

    @lir = compile_lir

    # Every time #plugin is invoked this is incremented to give each plugin
    # a unique id when auto-generating plugin ids
    @plugin_counter ||= 0

    @pipeline_id = @settings.get_value("pipeline.id") || self.object_id

    # A list of plugins indexed by id
    @plugins_by_id = {}
    @inputs = nil
    @filters = nil
    @outputs = nil
    @agent = agent

    if settings.get_value("dead_letter_queue.enable")
      @dlq_writer = DeadLetterQueueFactory.getWriter(pipeline_id, settings.get_value("path.dead_letter_queue"))
    else
      @dlq_writer = LogStash::Util::DummyDeadLetterQueueWriter.new
    end

    grammar = LogStashConfigParser.new
    parsed_config = grammar.parse(config_str)
    raise(ConfigurationError, grammar.failure_reason) if parsed_config.nil?

    config_code = parsed_config.compile

    # config_code = BasePipeline.compileConfig(config_str)

    if settings.get_value("config.debug") && @logger.debug?
      @logger.debug("Compiled pipeline code", default_logging_keys(:code => config_code))
    end

    # Evaluate the config compiled code that will initialize all the plugins and define the
    # filter and output methods.
    begin
      eval(config_code)
    rescue => e
      raise e
    end
  end

  def compile_lir
    source_with_metadata = org.logstash.common.SourceWithMetadata.new("str", "pipeline", self.config_str)
    LogStash::Compiler.compile_sources(source_with_metadata)
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
    @plugins_by_id[id] = true

    # use NullMetric if called in the BasePipeline context otherwise use the @metric value
    metric = @metric || Instrument::NullMetric.new

    pipeline_scoped_metric = metric.namespace([:stats, :pipelines, pipeline_id.to_s.to_sym, :plugins])
    # Scope plugins of type 'input' to 'inputs'
    type_scoped_metric = pipeline_scoped_metric.namespace("#{plugin_type}s".to_sym)

    klass = Plugin.lookup(plugin_type, name)

    execution_context = ExecutionContext.new(self, @agent, id, klass.config_name, @dlq_writer)

    if plugin_type == "output"
      OutputDelegator.new(@logger, klass, type_scoped_metric, execution_context, OutputDelegatorStrategyRegistry.instance, args)
    elsif plugin_type == "filter"
      FilterDelegator.new(@logger, klass, type_scoped_metric, execution_context, args)
    else # input
      input_plugin = klass.new(args)
      scoped_metric = type_scoped_metric.namespace(id.to_sym)
      scoped_metric.gauge(:name, input_plugin.config_name)
      input_plugin.metric = scoped_metric
      input_plugin.execution_context = execution_context
      input_plugin
    end
  end

  def reloadable?
    configured_as_reloadable? && reloadable_plugins?
  end

  def configured_as_reloadable?
    settings.get("pipeline.reloadable")
  end

  def reloadable_plugins?
    non_reloadable_plugins.empty?
  end

  def non_reloadable_plugins
    (inputs + filters + outputs).select { |plugin| !plugin.reloadable? }
  end
end; end

module LogStash; class Pipeline < BasePipeline
  attr_reader \
    :worker_threads,
    :events_consumed,
    :events_filtered,
    :reporter,
    :started_at,
    :thread,
    :settings,
    :metric,
    :filter_queue_client,
    :input_queue_client,
    :queue

  MAX_INFLIGHT_WARN_THRESHOLD = 10_000

  def initialize(pipeline_config, namespaced_metric = nil, agent = nil)
    @settings = pipeline_config.settings
    # This needs to be configured before we call super which will evaluate the code to make
    # sure the metric instance is correctly send to the plugins to make the namespace scoping work
    @metric = if namespaced_metric
      settings.get("metric.collect") ? namespaced_metric : Instrument::NullMetric.new(namespaced_metric.collector)
    else
      Instrument::NullMetric.new
    end

    @settings = settings
    @reporter = PipelineReporter.new(@logger, self)
    @worker_threads = []

    super

    begin
      @queue = LogStash::QueueFactory.create(settings)
    rescue => e
      @logger.error("Logstash failed to create queue", default_logging_keys("exception" => e.message, "backtrace" => e.backtrace))
      raise e
    end

    @input_queue_client = @queue.write_client
    @filter_queue_client = @queue.read_client
    @signal_queue = Queue.new
    # Note that @inflight_batches as a central mechanism for tracking inflight
    # batches will fail if we have multiple read clients here.
    @filter_queue_client.set_events_metric(metric.namespace([:stats, :events]))
    @filter_queue_client.set_pipeline_metric(
        metric.namespace([:stats, :pipelines, pipeline_id.to_s.to_sym, :events])
    )
    @drain_queue =  @settings.get_value("queue.drain")


    @events_filtered = Concurrent::AtomicFixnum.new(0)
    @events_consumed = Concurrent::AtomicFixnum.new(0)

    @input_threads = []
    # @ready requires thread safety since it is typically polled from outside the pipeline thread
    @ready = Concurrent::AtomicBoolean.new(false)
    @running = Concurrent::AtomicBoolean.new(false)
    @flushing = Concurrent::AtomicReference.new(false)
    @force_shutdown = Concurrent::AtomicBoolean.new(false)
  end # def initialize

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
        @logger.warn("Warning: Manual override - there are filters that might not work with multiple worker threads", default_logging_keys(:worker_threads => pipeline_workers, :filters => plugins))
      end
    else
      # user did not specify a worker thread count
      # warn if the default is multiple
      if default > 1
        @logger.warn("Defaulting pipeline worker threads to 1 because there are some filters that might not work with multiple worker threads",
                     default_logging_keys(:count_was => default, :filters => plugins))
        return 1 # can't allow the default value to propagate if there are unsafe filters
      end
    end
    pipeline_workers
  end

  def filters?
    return @filters.any?
  end

  def start
    # Since we start lets assume that the metric namespace is cleared
    # this is useful in the context of pipeline reloading
    collect_stats

    @logger.debug("Starting pipeline", default_logging_keys)

    @finished_execution = Concurrent::AtomicBoolean.new(false)

    @thread = Thread.new do
      begin
        LogStash::Util.set_thread_name("pipeline.#{pipeline_id}")
        run
        @finished_execution.make_true
      rescue => e
        close
        logger.error("Pipeline aborted due to error", default_logging_keys(:exception => e, :backtrace => e.backtrace))
      end
    end

    status = wait_until_started

    if status
      logger.debug("Pipeline started successfully", default_logging_keys(:pipeline_id => pipeline_id))
    end

    status
  end

  def wait_until_started
    while true do
      # This should be changed with an appropriate FSM
      # It's an edge case, if we have a pipeline with
      # a generator { count => 1 } its possible that `Thread#alive?` doesn't return true
      # because the execution of the thread was successful and complete
      if @finished_execution.true?
        return true
      elsif !thread.alive?
        return false
      elsif running?
        return true
      else
        sleep 0.01
      end
    end
  end

  def run
    @started_at = Time.now
    @thread = Thread.current
    Util.set_thread_name("[#{pipeline_id}]-pipeline-manager")

    start_workers

    @logger.info("Pipeline started", "pipeline.id" => @pipeline_id)

    # Block until all inputs have stopped
    # Generally this happens if SIGINT is sent and `shutdown` is called from an external thread

    transition_to_running
    start_flusher # Launches a non-blocking thread for flush events
    wait_inputs
    transition_to_stopped

    @logger.debug("Input plugins stopped! Will shutdown filter/output workers.", default_logging_keys)

    shutdown_flusher
    shutdown_workers

    close

    @logger.debug("Pipeline has been shutdown", default_logging_keys)

    # exit code
    return 0
  end # def run

  def close
    @filter_queue_client.close
    @queue.close
    @dlq_writer.close
  end

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

  def system?
    settings.get_value("pipeline.system")
  end

  # register_plugin simply calls the plugin #register method and catches & logs any error
  # @param plugin [Plugin] the plugin to register
  # @return [Plugin] the registered plugin
  def register_plugin(plugin)
    plugin.register
    plugin
  rescue => e
    @logger.error("Error registering plugin", default_logging_keys(:plugin => plugin.inspect, :error => e.message))
    raise e
  end

  # register_plugins calls #register_plugin on the plugins list and upon exception will call Plugin#do_close on all registered plugins
  # @param plugins [Array[Plugin]] the list of plugins to register
  def register_plugins(plugins)
    registered = []
    plugins.each { |plugin| registered << register_plugin(plugin) }
  rescue => e
    registered.each(&:do_close)
    raise e
  end

  def start_workers
    @worker_threads.clear # In case we're restarting the pipeline
    begin
      register_plugins(@outputs)
      register_plugins(@filters)

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

      @logger.info("Starting pipeline", default_logging_keys(
        "pipeline.workers" => pipeline_workers,
        "pipeline.batch.size" => batch_size,
        "pipeline.batch.delay" => batch_delay,
        "pipeline.max_inflight" => max_inflight))
      if max_inflight > MAX_INFLIGHT_WARN_THRESHOLD
        @logger.warn("CAUTION: Recommended inflight events max exceeded! Logstash will run with up to #{max_inflight} events in memory in your current configuration. If your message sizes are large this may cause instability with the default heap size. Please consider setting a non-standard heap size, changing the batch size (currently #{batch_size}), or changing the number of pipeline workers (currently #{pipeline_workers})", default_logging_keys)
      end

      pipeline_workers.times do |t|
        @worker_threads << Thread.new do
          Util.set_thread_name("[#{pipeline_id}]>worker#{t}")
          worker_loop(batch_size, batch_delay)
        end
      end

      # inputs should be started last, after all workers
      begin
        start_inputs
      rescue => e
        # if there is any exception in starting inputs, make sure we shutdown workers.
        # exception will already by logged in start_inputs
        shutdown_workers
        raise e
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
    shutdown_requested = false

    @filter_queue_client.set_batch_dimensions(batch_size, batch_delay)

    while true
      signal = @signal_queue.empty? ? NO_SIGNAL : @signal_queue.pop
      shutdown_requested |= signal.shutdown? # latch on shutdown signal

      batch = @filter_queue_client.read_batch # metrics are started in read_batch
      @events_consumed.increment(batch.size)
      filter_batch(batch)
      flush_filters_to_batch(batch, :final => false) if signal.flush?
      output_batch(batch)
      break if @force_shutdown.true? # Do not ack the current batch
      @filter_queue_client.close_batch(batch)

      # keep break at end of loop, after the read_batch operation, some pipeline specs rely on this "final read_batch" before shutdown.
      break if shutdown_requested && !draining_queue?
    end

    # we are shutting down, queue is drained if it was required, now  perform a final flush.
    # for this we need to create a new empty batch to contain the final flushed events
    batch = @filter_queue_client.new_batch
    @filter_queue_client.start_metrics(batch) # explicitly call start_metrics since we dont do a read_batch here
    flush_filters_to_batch(batch, :final => true)
    return if @force_shutdown.true? # Do not ack the current batch
    output_batch(batch)
    @filter_queue_client.close_batch(batch)
  end

  def filter_batch(batch)
    batch.each do |event|
      return if @force_shutdown.true?

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
                  default_logging_keys("exception" => e.message, "backtrace" => e.backtrace))

    raise e
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
      return if @force_shutdown.true?
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

    # first make sure we can register all input plugins
    register_plugins(@inputs)

    # then after all input plugins are successfully registered, start them
    @inputs.each { |input| start_input(input) }
  end

  def start_input(plugin)
    @input_threads << Thread.new { inputworker(plugin) }
  end

  def inputworker(plugin)
    Util::set_thread_name("[#{pipeline_id}]<#{plugin.class.config_name}")
    begin
      input_queue_client = wrapped_write_client(plugin)
      plugin.run(input_queue_client)
    rescue => e
      if plugin.stop?
        @logger.debug("Input plugin raised exception during shutdown, ignoring it.",
                      default_logging_keys(:plugin => plugin.class.config_name, :exception => e.message, :backtrace => e.backtrace))
        return
      end

      # otherwise, report error and restart
      if @logger.debug?
        @logger.error(I18n.t("logstash.pipeline.worker-error-debug",
                             default_logging_keys(
                               :plugin => plugin.inspect,
                               :error => e.message,
                               :exception => e.class,
                               :stacktrace => e.backtrace.join("\n"))))
      else
        @logger.error(I18n.t("logstash.pipeline.worker-error",
                             default_logging_keys(:plugin => plugin.inspect, :error => e.message)))
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
    # avoid potential race condition between the startup sequence and this
    # shutdown method which can be called from another thread at any time
    sleep(0.1) while !ready?

    # TODO: should we also check against calling shutdown multiple times concurrently?

    before_stop.call if block_given?

    stop_inputs

    # We make this call blocking, so we know for sure when the method return the shtudown is
    # stopped
    wait_for_workers
    clear_pipeline_metrics
    @logger.info("Pipeline terminated", "pipeline.id" => @pipeline_id)
  end # def shutdown

  def force_shutdown!
    @force_shutdown.make_true
  end

  def wait_for_workers
    @logger.debug("Closing inputs", default_logging_keys)
    @worker_threads.map(&:join)
    @logger.debug("Worker closed", default_logging_keys)
  end

  def stop_inputs
    @logger.debug("Closing inputs", default_logging_keys)
    @inputs.each(&:do_stop)
    @logger.debug("Closed inputs", default_logging_keys)
  end

  # After `shutdown` is called from an external thread this is called from the main thread to
  # tell the worker threads to stop and then block until they've fully stopped
  # This also stops all filter and output plugins
  def shutdown_workers
    # Each worker thread will receive this exactly once!
    @worker_threads.each do |t|
      @logger.debug("Pushing shutdown", default_logging_keys(:thread => t.inspect))
      @signal_queue.push(SHUTDOWN)
    end

    @worker_threads.each do |t|
      @logger.debug("Shutdown waiting for worker thread" , default_logging_keys(:thread => t.inspect))
      t.join
    end

    @filters.each(&:do_close)
    @outputs.each(&:do_close)
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
      return if @force_shutdown.true?
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
      @logger.debug? && @logger.debug("Pushing flush onto pipeline", default_logging_keys)
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
      return if @force_shutdown.true?

      unless event.cancelled?
        @logger.debug? and @logger.debug("Pushing flushed events", default_logging_keys(:event => event))
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

  def collect_stats
    pipeline_metric = @metric.namespace([:stats, :pipelines, pipeline_id.to_s.to_sym, :queue])
    pipeline_metric.gauge(:type, settings.get("queue.type"))

    if @queue.is_a?(LogStash::Util::WrappedAckedQueue) && @queue.queue.is_a?(LogStash::AckedQueue)
      queue = @queue.queue
      dir_path = queue.dir_path
      file_store = Files.get_file_store(Paths.get(dir_path))

      pipeline_metric.namespace([:capacity]).tap do |n|
        n.gauge(:page_capacity_in_bytes, queue.page_capacity)
        n.gauge(:max_queue_size_in_bytes, queue.max_size_in_bytes)
        n.gauge(:max_unread_events, queue.max_unread_events)
        n.gauge(:queue_size_in_bytes, queue.persisted_size_in_bytes)
      end
      pipeline_metric.namespace([:data]).tap do |n|
        n.gauge(:free_space_in_bytes, file_store.get_unallocated_space)
        n.gauge(:storage_type, file_store.type)
        n.gauge(:path, dir_path)
      end

      pipeline_metric.gauge(:events, queue.unread_count)
    end
  end

  def clear_pipeline_metrics
    # TODO(ph): I think the metric should also proxy that call correctly to the collector
    # this will simplify everything since the null metric would simply just do a noop
    collector = @metric.collector

    unless collector.nil?
      # selectively reset metrics we don't wish to keep after reloading
      # these include metrics about the plugins and number of processed events
      # we want to keep other metrics like reload counts and error messages
      collector.clear("stats/pipelines/#{pipeline_id}/plugins")
      collector.clear("stats/pipelines/#{pipeline_id}/events")
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

  private

  def default_logging_keys(other_keys = {})
    default_options = if thread
                        { :pipeline_id => pipeline_id, :thread => thread.inspect }
                      else
                        { :pipeline_id => pipeline_id }
                      end
    default_options.merge(other_keys)
  end

  def draining_queue?
    @drain_queue ? !@filter_queue_client.empty? : false
  end

  def wrapped_write_client(plugin)
    LogStash::Instrument::WrappedWriteClient.new(@input_queue_client, self, metric, plugin)
  end
end; end
