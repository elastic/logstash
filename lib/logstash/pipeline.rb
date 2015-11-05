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
require "logstash/util/reporter"
require "logstash/config/cpu_core_strategy"
require "logstash/util/defaults_printer"
require "logstash/util/wrapped_synchronous_queue"

class LogStash::Pipeline
  attr_reader :inputs, :filters, :outputs, :input_to_filter, :filter_to_output

  def initialize(configstr)
    @logger = Cabin::Channel.get(LogStash)

    @inputs = nil
    @filters = nil
    @outputs = nil

    grammar = LogStashConfigParser.new
    @config = grammar.parse(configstr)
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
    @input_threads = []

    @settings = {
      "filter-workers" => LogStash::Config::CpuCoreStrategy.fifty_percent
    }

    # @ready requires thread safety since it is typically polled from outside the pipeline thread
    @ready = Concurrent::AtomicBoolean.new(false)
  end # def initialize

  def ready?
    @ready.value
  end

  def configure(setting, value)
    if setting == "filter-workers" && value > 1
      # Abort if we have any filters that aren't threadsafe
      plugins = @filters.select { |f| !f.threadsafe? }.collect { |f| f.class.config_name }
      if !plugins.size.zero?
        raise LogStash::ConfigurationError, "Cannot use more than 1 filter worker because the following plugins don't work with more than one worker: #{plugins.join(", ")}"
      end
    end
    @settings[setting] = value
  end

  def filters?
    return @filters.any?
  end

  def run
    @logger.terminal(LogStash::Util::DefaultsPrinter.print(@settings))

    start_workers

    @logger.info("Pipeline started")
    @logger.terminal("Logstash startup completed")

    wait_inputs

    shutdown_workers

    @logger.info("Pipeline shutdown complete.")
    @logger.terminal("Logstash shutdown completed")

    # exit code
    return 0
  end # def run

  def start_workers
    @inflight_batches = {}
    @inflight_batches_mutex = Mutex.new
    begin
      start_inputs
      @outputs.each {|o| o.register }
      @filters.each {|f| f.register}

      @settings["filter-workers"].times do |t|
        Thread.new do
          LogStash::Util.set_thread_name(">worker#{t}")
          while true
            input_batch = take_event_batch
            set_current_thread_inflight_batch(input_batch)
            filtered_batch = filter_event_batch(input_batch)
            output_event_batch(filtered_batch)
            set_current_thread_inflight_batch(nil)
          end
        end
      end
    ensure
      # it is important to garantee @ready to be true after the startup sequence has been completed
      # to potentially unblock the shutdown method which may be waiting on @ready to proceed
      @ready.make_true
    end
  end

  def shutdown_workers
    inflight_batches_synchronize do |batches|
      puts "Current batches! #{batches.values.inspect}"
    end
    100.times { @input_queue.push(LogStash::SHUTDOWN) }
  end

  def set_current_thread_inflight_batch(batch)
    inflight_batches_synchronize do
      @inflight_batches[Thread.current] = batch
    end
  end

  def inflight_batches_synchronize
    @inflight_batches_mutex.synchronize do
      yield(@inflight_batches)
    end
  end

  def take_event_batch()
    batch = [@input_queue.take]
    19.times do
      event = @input_queue.poll(50)
      next if event.nil?
      batch << event
    end
    batch
  end

  def filter_event_batch(batch)
    filterable = batch.select {|e| e.is_a?LogStash::Event}
    filter_func(filterable).select {|e| !e.cancelled?}
  rescue Exception => e
    # Plugins authors should manage their own exceptions in the plugin code
    # but if an exception is raised up to the worker thread they are considered
    # fatal and logstash will not recover from this situation.
    #
    # Users need to check their configuration or see if there is a bug in the
    # plugin.
    @logger.error("Exception in filterworker, the pipeline stopped processing new events, please check your filter configuration and restart Logstash.",
                  "exception" => e, "backtrace" => e.backtrace)
    raise
  end

  def output_event_batch(batch)
    output_func(batch)
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

  def start_filters
    @filters.each(&:register)

  end

  def start_outputs
    @outputs.each(&:register)
  end

  def start_input(plugin)
    @input_threads << Thread.new { inputworker(plugin) }
  end

  def inputworker(plugin)
    LogStash::Util::set_thread_name("<#{plugin.class.config_name}")
    begin
      plugin.run(@input_queue)
    rescue => e
      # if plugin is stopping, ignore uncatched exceptions and exit worker
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

    @inputs.each(&:do_stop)
  end # def shutdown

  def plugin(plugin_type, name, *args)
    args << {} if args.empty?
    klass = LogStash::Plugin.lookup(plugin_type, name)
    return klass.new(*args)
  end

  # for backward compatibility in devutils for the rspec helpers, this method is not used
  # in the pipeline anymore.
  def filter(event, &block)
    # filter_func returns all filtered events, including cancelled ones
    filter_func(event).each { |e| block.call(e) }
  end
end # class Pipeline
