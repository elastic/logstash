# encoding: utf-8
require "logstash/config/file"
require "logstash/namespace"
require "thread" # stdlib
require "logstash/filters/base"
require "logstash/inputs/base"
require "logstash/outputs/base"
require "logstash/errors"
require "stud/interval" # gem stud

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
  end # def initialize

  def ready?
    return @ready
  end

  def started?
    return @started
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
    @started = true
    @input_threads = []
    start_inputs
    start_filters if filters?
    start_outputs

    # Set up the periodic flusher thread.
    @flusher_thread = Thread.new { Stud.interval(5) { break if terminating?; filter_flusher } }

    @ready = true

    @logger.info("Pipeline started")
    wait_inputs

    # In theory there's nothing to do to filters to tell them to shutdown?
    @terminating = true
    if filters?
      shutdown_filters
      wait_filters
    end
    filter_flusher

    shutdown_outputs
    wait_outputs

    @logger.info("Pipeline shutdown complete.")

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
    @input_to_filter.push(LogStash::ShutdownSignal)
  end

  def wait_filters
    @filter_threads.each(&:join) if @filter_threads
  end

  def shutdown_outputs
    # nothing, filters will do this
    @filter_to_output.push(LogStash::ShutdownSignal)
  end

  def wait_outputs
    # Wait for the outputs to stop
    @output_threads.each(&:join)
  end

  def start_inputs
    moreinputs = []
    @inputs.each do |input|
      if input.threadable && input.threads > 1
        (input.threads-1).times do |i|
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
    rescue LogStash::ShutdownSignal
      return
    rescue => e
      if @logger.debug?
        @logger.error(I18n.t("logstash.pipeline.worker-error-debug",
                             :plugin => plugin.inspect, :error => e.to_s,
                             :exception => e.class,
                             :stacktrace => e.backtrace.join("\n")))
      else
        @logger.error(I18n.t("logstash.pipeline.worker-error",
                             :plugin => plugin.inspect, :error => e))
      end
      puts e.backtrace if @logger.debug?
      plugin.teardown
      sleep 1
      retry
    end
  rescue LogStash::ShutdownSignal
    # nothing
  ensure
    plugin.teardown
  end # def inputworker

  def filterworker
    LogStash::Util::set_thread_name("|worker")
    begin
      while true
        event = @input_to_filter.pop
        if event == LogStash::ShutdownSignal
          @input_to_filter.push(event)
          break
        end


        # TODO(sissel): we can avoid the extra array creation here
        # if we don't guarantee ordering of origin vs created events.
        # - origin event is one that comes in naturally to the filter worker.
        # - created events are emitted by filters like split or metrics
        events = [event]
        filter(event) do |newevent|
          events << newevent
        end
        events.each do |event|
          next if event.cancelled?
          @filter_to_output.push(event)
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
      break if event == LogStash::ShutdownSignal
      output(event)
    end # while true
    @outputs.each(&:teardown)
  end # def outputworker

  # Shutdown this pipeline.
  #
  # This method is intended to be called from another thread
  def shutdown
    @input_threads.each do |thread|
      # Interrupt all inputs
      @logger.info("Sending shutdown signal to input thread",
                   :thread => thread)
      thread.raise(LogStash::ShutdownSignal)
      begin
        thread.wakeup # in case it's in blocked IO or sleeping
      rescue ThreadError
      end

      # Sometimes an input is stuck in a blocking I/O
      # so we need to tell it to teardown directly
      @inputs.each do |input|
        input.teardown
      end
    end

    # No need to send the ShutdownSignal to the filters/outputs nor to wait for
    # the inputs to finish, because in the #run method we wait for that anyway.
  end # def shutdown

  def terminating?
    return @terminating
  end

  def plugin(plugin_type, name, *args)
    args << {} if args.empty?
    klass = LogStash::Plugin.lookup(plugin_type, name)
    return klass.new(*args)
  end

  def filter(event, &block)
    @filter_func.call(event, &block)
  end

  def output(event)
    @output_func.call(event)
  end

  def filter_flusher
    @flushers.each do |flusher|
      flusher.call do |event|
        @logger.debug? and @logger.debug("Pushing flushed events", :event => event)
        @filter_to_output.push(event) unless event.cancelled?
      end
    end
  end # filter_Flusher

  def _filter_flusher
    events = []
    @filters.each do |filter|

      # Filter any events generated so far in this flush.
      events.each do |event|
        # TODO(sissel): watchdog on flush filtration?
        unless event.cancelled?
          filter.filter(event)
        end
      end

      # TODO(sissel): watchdog on flushes?
      if filter.respond_to?(:flush)
        flushed = filter.flush
        events += flushed if !flushed.nil? && flushed.any?
      end
    end

    events.each do |event|
      @logger.debug? and @logger.debug("Pushing flushed events", :event => event)
      @filter_to_output.push(event) unless event.cancelled?
    end
  end # def filter_flusher
end # class Pipeline
