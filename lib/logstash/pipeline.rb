require "logstash/config/file"
#require "logstash/agent" # only needed for now for parse_config
require "logstash/namespace"
require "thread" # stdlib
require "stud/trap"

class LogStash::Pipeline
  class ShutdownSignal < StandardError; end

  def initialize(configstr)
    # hacks for now to parse a config string
    config = LogStash::Config::File.new(nil, configstr)
    @inputs, @filters, @outputs = parse_config(config)

    @input_to_filter = SizedQueue.new(20)
    @filter_to_output = SizedQueue.new(20)

    # If no filters, pipe inputs directly to outputs
    if @filters.empty?
      @input_to_filter = @filter_to_output
    end

    @logger = Cabin::Channel.get(LogStash)
    (@inputs + @filters + @outputs).each do |plugin|
      plugin.logger = @logger
    end

    @inputs.each(&:register)
    @filters.each(&:register)
    @outputs.each(&:register)
  end # def initialize

  # Parses a config and returns [inputs, filters, outputs]
  def parse_config(config)
    # TODO(sissel): Move this method to config/file.rb
    inputs = []
    filters = []
    outputs = []
    config.parse do |plugin|
      # 'plugin' is a has containing:
      #   :type => the base class of the plugin (LogStash::Inputs::Base, etc)
      #   :plugin => the class of the plugin (LogStash::Inputs::File, etc)
      #   :parameters => hash of key-value parameters from the config.
      type = plugin[:type].config_name  # "input" or "filter" etc...
      klass = plugin[:plugin]

      # Create a new instance of a plugin, called like:
      # -> LogStash::Inputs::File.new( params )
      instance = klass.new(plugin[:parameters])
      instance.logger = @logger

      case type
        when "input"
          inputs << instance
        when "filter"
          filters << instance
        when "output"
          outputs << instance
        else
          msg = "Unknown config type '#{type}'"
          @logger.error(msg)
          raise msg
      end # case type
    end # config.parse
    return inputs, filters, outputs
  end # def parse_config

  def run
    start = Time.now

    # one thread per input
    @input_threads = @inputs.collect do |input|
      Thread.new(input) do |input|
        inputworker(input)
      end
    end

    # one filterworker thread
    #@filter_threads = @filters.collect do |input
    # TODO(sissel): THIS IS WHERE I STOPPED WORKING

    # one outputworker thread

    @output_thread = Thread.new do 
      outputworker
    end

    @logger.info("Pipeline started")
    
    @input_threads.each(&:join)

    # All input plugins have completed, send a shutdown signal.
    duration = Time.now - start
    puts "Duration: #{duration}"

    @input_to_filter.push(ShutdownSignal)

    # Wait for filters to stop
    @filter_threads.each(&:join) if @filter_threads

    # Wait for the outputs to stop
    @output_thread.join

    @logger.info("Pipeline shutdown complete.")

    # exit code
    return 0
  end # def run

  def inputworker(plugin)
    begin
      plugin.run(@input_to_filter)
    rescue ShutdownSignal
      plugin.teardown
    rescue => e
      @logger.error(I18n.t("logstash.pipeline.worker-error",
                           :plugin => plugin.inspect, :error => e))
      puts e.backtrace
      plugin.teardown
      retry
    end
  end # def inputworker

  def filterworker
    begin
      while true
        event = @input_to_filter.pop
        break if event == ShutdownSignal

        # Apply filters, in order, to the event.
        @filters.each do |filter|
          filter.execute(event)
        end
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
    while true
      event = @filter_to_output.pop
      break if event == ShutdownSignal

      @outputs.each do |output|
        begin
          output.receive(event)
        rescue => e
          @logger.error("Exception in plugin #{plugin.class}",
                        "plugin" => plugin.inspect, "exception" => e)
        end
      end # @outputs.each
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
end # class Pipeline
