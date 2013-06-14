require "logstash/config/file"
require "logstash/namespace"
require "thread" # stdlib
require "stud/trap"
require "logstash/filters/base"
require "logstash/inputs/base"
require "logstash/outputs/base"

class LogStash::Pipeline
  class ShutdownSignal < StandardError; end

  def initialize(configstr)
    grammar = LogStashConfigParser.new
    @config = grammar.parse(configstr)
    if @config.nil?
      raise LogStash::ConfigurationError, grammar.failure_reason
    end

    @input_to_filter = SizedQueue.new(20)

    # If no filters, pipe inputs directly to outputs
    if !filters?
      @filter_to_output = @input_to_filter
    else
      @filter_to_output = SizedQueue.new(20)
    end

    @logger = Cabin::Channel.get(LogStash)

    puts compile_config
    eval(compile_config)
  end # def initialize

  def filters?
    return @config.recursive_select(LogStash::Config::AST::Plugin).any? { |p| p.plugin_type == "filter" }
  end

  def compile_config
    code = []
    code << "@inputs = []"
    code << "@filters = []"
    code << "@outputs = []"
    sections = @config.recursive_select(LogStash::Config::AST::PluginSection)
    sections.each do |s|
      code << s.compile_initializer
    end

    # start inputs
    code << "class << self"
    definitions = []
      
    ["filter", "output"].each do |type|
      definitions << "def #{type}(event)"
      definitions << "  @logger.info(\"#{type} received\", :event => event)"
      sections.select { |s| s.plugin_type.text_value == type }.each do |s|
        definitions << s.compile.split("\n").map { |e| "  #{e}" }.join("\n")
      end
      definitions << "end"
    end

    code += definitions.collect { |l| "  #{l}" }
    code << "end"
    return code.join("\n")
  end

  def run
    @input_threads = []
    start_inputs
    start_filters if filters?
    start_outputs

    @logger.info("Pipeline started")
    wait_inputs
    shutdown_filters
    wait_filters
    shutdown_outputs
    wait_outputs

    @logger.info("Pipeline shutdown complete.")

    # exit code
    return 0
  end # def run

  def wait_inputs
    @input_threads.each(&:join)
  end

  def shutdown_filters
    @input_to_filter.push(ShutdownSignal)
  end

  def wait_filters
    @filter_threads.each(&:join) if @filter_threads
  end

  def shutdown_outputs
    # nothing, filters will do this
  end

  def wait_outputs
    # Wait for the outputs to stop
    @output_thread.join
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
      start_input(input)
    end
  end

  def start_filters
    @filter_threads = [
      Thread.new { filterworker }
    ]
  end

  def start_outputs
    @output_thread = Thread.new do 
      outputworker
    end
  end

  def start_input(plugin)
    @input_threads << Thread.new { inputworker(plugin) }
  end

  def inputworker(plugin)
    LogStash::Util::set_thread_name("<#{plugin.class.config_name}")
    begin
      plugin.run(@input_to_filter)
    rescue ShutdownSignal
      plugin.teardown
    rescue => e
      if @logger.debug?
        @logger.error(I18n.t("logstash.pipeline.worker-error-debug",
                             :plugin => plugin.inspect, :error => e,
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
  end # def inputworker

  def filterworker
    LogStash::Util::set_thread_name("|worker")
    @filters.each(&:register)
    begin
      while true
        event = @input_to_filter.pop
        break if event == ShutdownSignal
        filter(event)
        next if event.cancelled?
        @filter_to_output.push(event)
      end
    rescue => e
      @logger.error("Exception in plugin #{plugin.class}",
                    "plugin" => plugin.inspect, "exception" => e)
    end

    @filters.each(&:teardown)
  end # def filterworker

  def outputworker
    LogStash::Util::set_thread_name(">output")
    @outputs.each(&:register)
    while true
      event = @filter_to_output.pop
      break if event == ShutdownSignal
      output(event)
    end # while true
    @outputs.each(&:teardown)
  end # def filterworker

  # Shutdown this pipeline.
  #
  # This method is intended to be called from another thread
  def shutdown
    @input_threads.each do |thread|
      # Interrupt all inputs
      @logger.info("Sending shutdown signal to input thread",
                   :thread => thread)
      thread.raise(ShutdownSignal)
      thread.wakeup # in case it's in blocked IO or sleeping
    end

    # No need to send the ShutdownSignal to the filters/outputs nor to wait for
    # the inputs to finish, because in the #run method we wait for that anyway.
  end # def shutdown

  def plugin(plugin_type, name, *args)
    args << {} if args.empty?
    klass = LogStash::Plugin.lookup(plugin_type, name)
    return klass.new(*args)
  end
end # class Pipeline
