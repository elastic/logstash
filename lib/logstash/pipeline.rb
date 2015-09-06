# encoding: utf-8
require "thread" #
require "stud/interval"
require "logstash/namespace"
require "logstash/errors"
require "logstash/event"
require "logstash/config/file"
require "logstash/filters/base"
require "logstash/inputs/base"
require "logstash/outputs/base"
require "logstash/util/reporter"

class LogStash::Pipeline

  def initialize(configstr)
    @logger = Cabin::Channel.get(LogStash)
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

    @input_to_filter = SizedQueue.new(20)

    # If no filters, pipe inputs directly to outputs
    if !filters?
      @filter_to_output = @input_to_filter
    else
      @filter_to_output = SizedQueue.new(20)
    end
    @settings = {
      "filter-workers" => 1,
    }

    @run_mutex = Mutex.new
    @ready = false
    @started = false
    @input_threads = []
  end # def initialize

  def ready?
    @run_mutex.synchronize{@ready}
  end

  def started?
    @run_mutex.synchronize{@started}
  end

  def configure(setting, value)
    if setting == "filter-workers"
      # Abort if we have any filters that aren't threadsafe
      if value > 1 && @filters.any? { |f| !f.threadsafe? }
        plugins = @filters.select { |f| !f.threadsafe? }.collect { |f| f.class.config_name }
        raise LogStash::ConfigurationError, "Cannot use more than 1 filter worker because the following plugins don't work with more than one worker: #{plugins.join(", ")}"
      end
    end
    @settings[setting] = value
  end

  def filters?
    return @filters.any?
  end

  def run
    @run_mutex.synchronize{@started = true}

    # synchronize @input_threads between run and shutdown
    @run_mutex.synchronize{start_inputs}
    start_filters if filters?
    start_outputs

    @run_mutex.synchronize{@ready = true}

    @logger.info("Pipeline started")
    @logger.terminal("Logstash startup completed")

    wait_inputs

    if filters?
      shutdown_filters
      wait_filters
      flush_filters_to_output!(:final => true)
    end

    shutdown_outputs
    wait_outputs

    @logger.info("Pipeline shutdown complete.")
    @logger.terminal("Logstash shutdown completed")

    # exit code
    return 0
  end # def run

  def wait_inputs
    @input_threads.each(&:join)
  rescue Interrupt
    # rbx does weird things during do SIGINT that I haven't debugged
    # so we catch Interrupt here and signal a shutdown. For some reason the
    # signal handler isn't invoked it seems? I dunno, haven't looked much into
    # it.
    shutdown
  end

  def shutdown_filters
    @flusher_thread.kill
    @input_to_filter.push(LogStash::SHUTDOWN)
  end

  def wait_filters
    @filter_threads.each(&:join) if @filter_threads
  end

  def shutdown_outputs
    # nothing, filters will do this
    @filter_to_output.push(LogStash::SHUTDOWN)
  end

  def wait_outputs
    # Wait for the outputs to stop
    @output_threads.each(&:join)
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
    @filter_threads = @settings["filter-workers"].times.collect do
      Thread.new { filterworker }
    end

    @flusher_thread = Thread.new { Stud.interval(5) { @input_to_filter.push(LogStash::FLUSH) } }
  end

  def start_outputs
    @outputs.each(&:register)
    @output_threads = [
      Thread.new { outputworker }
    ]
  end

  def start_input(plugin)
    @input_threads << Thread.new { inputworker(plugin) }
  end

  def inputworker(plugin)
    LogStash::Util::set_thread_name("<#{plugin.class.config_name}")
    begin
      plugin.run(@input_to_filter)
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
      plugin.teardown
    end
  end # def inputworker

  def filterworker
    LogStash::Util::set_thread_name("|worker")
    begin
      while true
        event = @input_to_filter.pop

        case event
        when LogStash::Event
          # filter_func returns all filtered events, including cancelled ones
          filter_func(event).each { |e| @filter_to_output.push(e) unless e.cancelled? }
        when LogStash::FlushEvent
          # handle filter flushing here so that non threadsafe filters (thus only running one filterworker)
          # don't have to deal with thread safety implementing the flush method
          flush_filters_to_output!
        when LogStash::ShutdownEvent
          # pass it down to any other filterworker and stop this worker
          @input_to_filter.push(event)
          break
        end
      end
    rescue => e
      @logger.error("Exception in filterworker", "exception" => e, "backtrace" => e.backtrace)
    end

    @filters.each(&:teardown)
  end # def filterworker

  def outputworker
    LogStash::Util::set_thread_name(">output")
    @outputs.each(&:worker_setup)

    while true
      event = @filter_to_output.pop
      break if event == LogStash::SHUTDOWN
      output_func(event)
    end
  ensure
    @outputs.each do |output|
      output.worker_plugins.each(&:teardown)
    end
  end # def outputworker

  # Shutdown this pipeline.
  #
  # This method is intended to be called from another thread
  def shutdown
    InflightEventsReporter.logger = @logger
    InflightEventsReporter.start(@input_to_filter, @filter_to_output, @outputs)

    # sometimes an input is stuck in a blocking I/O so we need to tell it to teardown directly
    @inputs.each do |input|
      begin
        # input teardown must be synchronized since is can be called concurrently by
        # the input worker thread and from the pipeline thread shutdown method.
        # this means that input teardown methods must support multiple calls.
        @run_mutex.synchronize{input.stop}
      rescue LogStash::ShutdownSignal
        # teardown could receive the ShutdownSignal, retry it
        retry
      end
    end
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

  # perform filters flush and yeild flushed event to the passed block
  # @param options [Hash]
  # @option options [Boolean] :final => true to signal a final shutdown flush
  def flush_filters(options = {}, &block)
    flushers = options[:final] ? @shutdown_flushers : @periodic_flushers

    flushers.each do |flusher|
      flusher.call(options, &block)
    end
  end

  # perform filters flush into the output queue
  # @param options [Hash]
  # @option options [Boolean] :final => true to signal a final shutdown flush
  def flush_filters_to_output!(options = {})
    flush_filters(options) do |event|
      unless event.cancelled?
        @logger.debug? and @logger.debug("Pushing flushed events", :event => event)
        @filter_to_output.push(event)
      end
    end
  end # flush_filters_to_output!

end # class Pipeline
