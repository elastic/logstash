# encoding: utf-8
require "thread"
require "stud/interval"
require "logstash/namespace"
require "logstash/errors"
require "logstash/event"
require "logstash/config/file"
require "logstash/filters/base"
require "logstash/inputs/base"
require "logstash/outputs/base"

require "jruby-mmap-queues"
require "logstash/queue_serializer"

class LogStash::Pipeline
  FLUSH_EVENT = LogStash::FlushEvent.new

  MAX_QUEUE_ITEMS = 20
  INPUT_QUEUE_FILE = "input_to_filter_queue".freeze
  FILTER_QUEUE_FILE = "filter_to_output_queue".freeze

  # settings keys constants
  SETTINGS_FILTER_WORKERS = "filter-workers".freeze
  SETTINGS_USE_PERSISTENT_QUEUES = "use-persistent-queues".freeze
  SETTINGS_PERSISTENT_QUEUES_PATH = "persistent-queues-path".freeze
  SETTINGS_PERSISTENT_QUEUES_ITEMS = "persistent-queues-items".freeze
  SETTINGS_PERSISTENT_QUEUES_PAGESIZE = "persistent-queues-pagesize".freeze

  def initialize(configstr)
    @logger = Cabin::Channel.get(LogStash)

    LogStashConfigParser.new.tap do |grammar|
      @config = grammar.parse(configstr)
      raise LogStash::ConfigurationError, grammar.failure_reason if @config.nil?
    end

    # This will compile the config to ruby and evaluate the resulting code.
    # The code will initialize all the plugins and define the filter and output methods.
    @config.compile.tap do |code|
      @logger.debug? && @logger.debug("Compiled pipeline code:\n#{code}")
      eval(code)
    end

    # defaults settings
    @settings = {
      SETTINGS_FILTER_WORKERS => 1,
      SETTINGS_USE_PERSISTENT_QUEUES => false,
      SETTINGS_PERSISTENT_QUEUES_PATH => "./",
      SETTINGS_PERSISTENT_QUEUES_ITEMS => MAX_QUEUE_ITEMS,
      SETTINGS_PERSISTENT_QUEUES_PAGESIZE => MAX_QUEUE_ITEMS * 1024 * 1024,
    }
  end # def initialize

  def ready?
    return @ready
  end

  def started?
    return @started
  end

  def configure(setting, value)
    if setting == SETTINGS_FILTER_WORKERS
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

    @input_to_filter = create_input_queue
    @filter_to_output = create_filter_queue

    start_inputs
    start_filters if filters?
    start_outputs

    @ready = true

    @logger.info("Pipeline started")
    wait_inputs

    if filters?
      shutdown_filters
      wait_filters
      flush_filters_to_output!(:final => true)
    end

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
    @flusher_lock.synchronize { @flusher_thread.kill }
    @input_to_filter.push(LogStash::ShutdownEvent.new)
  end

  def wait_filters
    @filter_threads.each(&:join) if @filter_threads
  end

  def shutdown_outputs
    # nothing, filters will do this
    @filter_to_output.push(LogStash::ShutdownEvent.new)
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
    @filter_threads = @settings[SETTINGS_FILTER_WORKERS].times.collect { Thread.new { filterworker } }

    @flusher_lock = Mutex.new
    @flusher_thread = Thread.new { Stud.interval(5) { @flusher_lock.synchronize { @input_to_filter.push(FLUSH_EVENT) } } }
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

        case event
        when LogStash::Event
          # use events array to guarantee ordering of origin vs created events
          # where created events are emitted by filters like split or metrics
          events = []
          filter(event) { |newevent| events << newevent }
          events.each { |event| @filter_to_output.push(event) }
        when LogStash::FlushEvent
          # handle filter flushing here so that non threadsafe filters (thus only running one filterworker)
          # don't have to deal with thread safety implementing the flush method
          @flusher_lock.synchronize { flush_filters_to_output! }
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

    # assign new queue to output with multiple workers
    @outputs.select(&:has_workers?).each{|output| output.workers_setup(create_output_queue(output.class.config_name))}

    while true
      event = @filter_to_output.pop
      break if event.is_a?(LogStash::ShutdownEvent)
      output(event)
    end

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
        # ignore
      end

      # Sometimes an input is stuck in a blocking I/O
      # so we need to tell it to teardown directly
      @inputs.each do |input|
        input.teardown
      end
    end

    # No need to send the ShutdownEvent to the filters/outputs nor to wait for
    # the inputs to finish, because in the #run method we wait for that anyway.
  end # def shutdown

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

  private

  def create_input_queue
    create_sized_queue(INPUT_QUEUE_FILE)
  end

  def create_filter_queue
    # if no filters, pipe inputs directly to outputs
    filters? ? create_sized_queue(FILTER_QUEUE_FILE) : @input_to_filter
  end

  def create_output_queue(name)
    # config can contain multiple output of the same type thus having the same config_name
    # to avoid persistent queue file name clash make sure to make them unique
    create_sized_queue(uniquify(name))
  end

  def create_sized_queue(name)
    if @settings[SETTINGS_USE_PERSISTENT_QUEUES]
      Mmap::SizedQueue.new(@settings[SETTINGS_PERSISTENT_QUEUES_ITEMS],
        :page_handler => Mmap::SinglePage.new(File.expand_path(name, @settings[SETTINGS_PERSISTENT_QUEUES_PATH]), :page_size => @settings[SETTINGS_PERSISTENT_QUEUES_PAGESIZE]),
        :serializer => LogStash::JsonSerializer.new
      )
    else
      SizedQueue.new(MAX_QUEUE_ITEMS)
    end
  end

  # @param id [String] any string id we want to make unique
  # @return [String] the original id with possibly an appended number to make it unique
  def uniquify(id)
    @unique_ids_index ||= 0
    @unique_ids ||= {}
    id = "#{id}-#{@unique_ids_index += 1}" while @unique_ids.has_key?(id)
    @unique_ids[id] = true
    id
  end

end # class Pipeline
