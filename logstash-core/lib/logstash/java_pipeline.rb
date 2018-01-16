# encoding: utf-8
require "thread"
require "stud/interval"
require "concurrent"
require "logstash/namespace"
require "logstash/errors"
require "logstash-core/logstash-core"
require "logstash/event"
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
require "logstash/java_filter_delegator"
require "logstash/queue_factory"
require "logstash/compiler"
require "logstash/execution_context"
require "securerandom"

java_import org.logstash.common.DeadLetterQueueFactory
java_import org.logstash.common.SourceWithMetadata
java_import org.logstash.common.io.DeadLetterQueueWriter
java_import org.logstash.config.ir.CompiledPipeline
java_import org.logstash.config.ir.ConfigCompiler

module LogStash; class JavaBasePipeline
  include LogStash::Util::Loggable

  attr_reader :settings, :config_str, :config_hash, :inputs, :filters, :outputs, :pipeline_id, :lir, :execution_context, :ephemeral_id
  attr_reader :pipeline_config

  def initialize(pipeline_config, namespaced_metric = nil, agent = nil)
    @logger = self.logger
    @mutex = Mutex.new
    @ephemeral_id = SecureRandom.uuid

    @pipeline_config = pipeline_config
    @config_str = pipeline_config.config_string
    @settings = pipeline_config.settings
    @config_hash = Digest::SHA1.hexdigest(@config_str)

    @lir = ConfigCompiler.configToPipelineIR(
      @config_str, @settings.get_value("config.support_escapes")
    )

    @pipeline_id = @settings.get_value("pipeline.id") || self.object_id
    @agent = agent
    @dlq_writer = dlq_writer
    @plugin_factory = LogStash::Plugins::PluginFactory.new(
      # use NullMetric if called in the BasePipeline context otherwise use the @metric value
      @lir, LogStash::Plugins::PluginMetricFactory.new(pipeline_id, @metric || Instrument::NullMetric.new),
      LogStash::Plugins::ExecutionContextFactory.new(@agent, self, @dlq_writer),
      JavaFilterDelegator
    )
    @lir_execution = CompiledPipeline.new(@lir, @plugin_factory)
    if settings.get_value("config.debug") && @logger.debug?
      @logger.debug("Compiled pipeline code", default_logging_keys(:code => @lir.get_graph.to_string))
    end
    @inputs = @lir_execution.inputs
    @filters = @lir_execution.filters
    @outputs = @lir_execution.outputs
  end

  def dlq_writer
    if settings.get_value("dead_letter_queue.enable")
      @dlq_writer = DeadLetterQueueFactory.getWriter(pipeline_id, settings.get_value("path.dead_letter_queue"), settings.get_value("dead_letter_queue.max_bytes"))
    else
      @dlq_writer = LogStash::Util::DummyDeadLetterQueueWriter.new
    end
  end

  def close_dlq_writer
    @dlq_writer.close
    if settings.get_value("dead_letter_queue.enable")
      DeadLetterQueueFactory.release(pipeline_id)
    end
  end

  def buildOutput(name, line, column, *args)
    plugin("output", name, line, column, *args)
  end

  def buildFilter(name, line, column, *args)
    plugin("filter", name, line, column, *args)
  end

  def buildInput(name, line, column, *args)
    plugin("input", name, line, column, *args)
  end

  def buildCodec(name, *args)
   plugin("codec", name, 0, 0, *args)
  end

  def plugin(plugin_type, name, line, column, *args)
    @plugin_factory.plugin(plugin_type, name, line, column, *args)
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

  private

  def default_logging_keys(other_keys = {})
    { :pipeline_id => pipeline_id }.merge(other_keys)
  end
end; end

module LogStash; class JavaPipeline < JavaBasePipeline
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

    @ephemeral_id = SecureRandom.uuid
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
    @signal_queue = java.util.concurrent.LinkedBlockingQueue.new
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
    @outputs_registered = Concurrent::AtomicBoolean.new(false)
    @finished_execution = Concurrent::AtomicBoolean.new(false)
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
    @filters.any?
  end

  def start
    # Since we start lets assume that the metric namespace is cleared
    # this is useful in the context of pipeline reloading
    collect_stats
    collect_dlq_stats

    @logger.debug("Starting pipeline", default_logging_keys)

    @finished_execution.make_false

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
      elsif thread.nil? || !thread.alive?
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
    close_dlq_writer
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

  # register_plugins calls #register_plugin on the plugins list and upon exception will call Plugin#do_close on all registered plugins
  # @param plugins [Array[Plugin]] the list of plugins to register
  def register_plugins(plugins)
    registered = []
    plugins.each do |plugin|
      plugin.register
      registered << plugin
    end
  rescue => e
    registered.each(&:do_close)
    raise e
  end

  def start_workers
    @worker_threads.clear # In case we're restarting the pipeline
    @outputs_registered.make_false
    begin
      maybe_setup_out_plugins

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
      config_metric.gauge(:dead_letter_queue_enabled, dlq_enabled?)
      config_metric.gauge(:dead_letter_queue_path, @dlq_writer.get_path.to_absolute_path.to_s) if dlq_enabled?


      @logger.info("Starting pipeline", default_logging_keys(
        "pipeline.workers" => pipeline_workers,
        "pipeline.batch.size" => batch_size,
        "pipeline.batch.delay" => batch_delay,
        "pipeline.max_inflight" => max_inflight))
      if max_inflight > MAX_INFLIGHT_WARN_THRESHOLD
        @logger.warn("CAUTION: Recommended inflight events max exceeded! Logstash will run with up to #{max_inflight} events in memory in your current configuration. If your message sizes are large this may cause instability with the default heap size. Please consider setting a non-standard heap size, changing the batch size (currently #{batch_size}), or changing the number of pipeline workers (currently #{pipeline_workers})", default_logging_keys)
      end

      @filter_queue_client.set_batch_dimensions(batch_size, batch_delay)

      pipeline_workers.times do |t|
        batched_execution = @lir_execution.buildExecution
        thread = Thread.new(self, batched_execution) do |_pipeline, _batched_execution|
          _pipeline.worker_loop(_batched_execution)
        end
        thread.name="[#{pipeline_id}]>worker#{t}"
        @worker_threads << thread
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

  def dlq_enabled?
    @settings.get("dead_letter_queue.enable")
  end

  # Main body of what a worker thread does
  # Repeatedly takes batches off the queue, filters, then outputs them
  def worker_loop(batched_execution)
    shutdown_requested = false
    while true
      signal = @signal_queue.poll || NO_SIGNAL
      shutdown_requested |= signal.shutdown? # latch on shutdown signal

      batch = @filter_queue_client.read_batch # metrics are started in read_batch
      @events_consumed.increment(batch.size)
      execute_batch(batched_execution, batch, signal.flush?)
      @filter_queue_client.close_batch(batch)
      # keep break at end of loop, after the read_batch operation, some pipeline specs rely on this "final read_batch" before shutdown.
      break if (shutdown_requested && !draining_queue?)
    end

    # we are shutting down, queue is drained if it was required, now  perform a final flush.
    # for this we need to create a new empty batch to contain the final flushed events
    batch = @filter_queue_client.new_batch
    @filter_queue_client.start_metrics(batch) # explicitly call start_metrics since we dont do a read_batch here
    batched_execution.compute(batch.to_a, true, true)
    @filter_queue_client.close_batch(batch)
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
      @logger.error(I18n.t("logstash.pipeline.worker-error-debug",
                            default_logging_keys(
                              :plugin => plugin.inspect,
                              :error => e.message,
                              :exception => e.class,
                              :stacktrace => e.backtrace.join("\n"))))

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
      @signal_queue.put(SHUTDOWN)
    end

    @worker_threads.each do |t|
      @logger.debug("Shutdown waiting for worker thread" , default_logging_keys(:thread => t.inspect))
      t.join
    end

    @filters.each(&:do_close)
    @outputs.each(&:do_close)
  end

  # for backward compatibility in devutils for the rspec helpers, this method is not used
  # anymore and just here to not break TestPipeline that inherits this class.
  def filter(event, &block)
  end

  # for backward compatibility in devutils for the rspec helpers, this method is not used
  # anymore and just here to not break TestPipeline that inherits this class.
  def flush_filters(options = {}, &block)
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
      @signal_queue.put(FLUSH)
    end
  end

  # Calculate the uptime in milliseconds
  #
  # @return [Fixnum] Uptime in milliseconds, 0 if the pipeline is not started
  def uptime
    return 0 if started_at.nil?
    ((Time.now.to_f - started_at.to_f) * 1000.0).to_i
  end

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

  def collect_dlq_stats
    if dlq_enabled?
      dlq_metric = @metric.namespace([:stats, :pipelines, pipeline_id.to_s.to_sym, :dlq])
      dlq_metric.gauge(:queue_size_in_bytes, @dlq_writer.get_current_queue_size)
    end
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

  def execute_batch(batched_execution, batch, flush)
    batched_execution.compute(batch.to_a, flush, false)
    @events_filtered.increment(batch.size)
    filtered_size = batch.filtered_size
    @filter_queue_client.add_output_metrics(filtered_size)
    @filter_queue_client.add_filtered_metrics(filtered_size)
    @flushing.set(false) if flush
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

  def maybe_setup_out_plugins
    if @outputs_registered.make_true
      register_plugins(@outputs)
      register_plugins(@filters)
    end
  end

  def default_logging_keys(other_keys = {})
    keys = super
    keys[:thread] ||= thread.inspect if thread
    keys
  end

  def draining_queue?
    @drain_queue ? !@filter_queue_client.empty? : false
  end

  def wrapped_write_client(plugin)
    #need to ensure that metrics are initialized one plugin at a time, else a race condition can exist.
    @mutex.synchronize do
      LogStash::Instrument::WrappedWriteClient.new(@input_queue_client, self, metric, plugin)
    end
  end
end; end
