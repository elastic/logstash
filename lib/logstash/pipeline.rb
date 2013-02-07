require "logstash/config/file"
require "logstash/agent" # only needed for now for parse_config
require "logstash/namespace"
require "thread" # stdlib
require "stud/trap"

class LogStash::Pipeline
  class ShutdownSignal; end

  def initialize(configstr)
    # hacks for now to parse a config string
    config = LogStash::Config::File.new(nil, configstr)
    agent = LogStash::Agent.new
    @inputs, @filters, @outputs = agent.instance_eval { parse_config(config) }

    @input_to_filter = SizedQueue.new(20)
    @filter_to_output = SizedQueue.new(20)

    # If no filters, pipe inputs directly to outputs
    if @filters.empty?
      @input_to_filter = @filter_to_output
    end

    logger = Cabin::Channel.get
    (@inputs + @filters + @outputs).each do |plugin|
      plugin.logger = logger
    end

    @inputs.each(&:register)
    @filters.each(&:register)
    @outputs.each(&:register)
  end

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
    
    @input_threads.each(&:join)

    # All input plugins have completed, send a shutdown signal.
    duration = Time.now - start
    puts "Duration: #{duration}"

    @input_to_filter.push(ShutdownSignal)
    @output_thread.join

    # exit code
    return 0
  end # def run

  def inputworker(plugin)
    begin
      plugin.run(@input_to_filter)
    rescue ShutdownSignal
      plugin.teardown
    rescue => e
      @logger.error("Exception in plugin #{plugin.class}, restarting plugin.",
                    "plugin" => plugin.inspect, "exception" => e)
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
      thread.raise(ShutdownSignal.new)
    end
    @filter_to_output.push(ShutdownSignal)
  end # def shutdown
end # class Pipeline
