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
    @config = LogStash::Config::File.new(configstr)
    @input_to_filter = SizedQueue.new(20)

    # If no filters, pipe inputs directly to outputs
    if @config.none? { |p| p.is_a?(LogStash::Filters::Base) }
      @filter_to_output = @input_to_filter
    else
      @filter_to_output = SizedQueue.new(20)
    end

    @logger = Cabin::Channel.get(LogStash)

    if @config.none? { |p| p.is_a?(LogStash::Filters::Base) }
      @input_to_filter = @filter_to_output
    end
  end # def initialize

  def run
    # For each input plugin, instantiate it and run as many as required by the
    # 'threads' setting.
    #
    # For filters, generate code to execute the filters as declared
    # For outputs, generate code to execute the outputs as declared
    
    inputs.each do |input|
      Thread.new(input) do |input|
        input.run(queue)
      end
    end

    filterworker_count.times do

    end
    start_inputs
    start_filters
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
    inputs = @config.select { |p| p.is_a?(LogStash::Inputs::Base) }
    # one thread per input
    @input_threads = inputs.collect do |input|
      input.register
      input.logger = @logger
      Thread.new(input) do |input|
        inputworker(input)
      end
    end
  end

  def start_filters
  end

  def start_outputs
    @output_thread = Thread.new do 
      outputworker
    end
  end

  def inputworker(plugin)
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
    outputs = @config.select { |p| p.is_a?(LogStash::Outputs::Base) }
    outputs.each do |output|
      output.register
      output.logger = @logger
    end
    while true
      event = @filter_to_output.pop
      break if event == ShutdownSignal

      outputs.each do |output|
        begin
          output.receive(event)
        rescue => e
          @logger.error("Exception in plugin #{output.class}",
                        "plugin" => output.inspect, "exception" => e, "stack" => e.backtrace)
        end
      end # @outputs.each
    end # while true
    outputs.each(&:teardown)
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
