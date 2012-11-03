$: << "lib"
require "logstash/config/file"

class Pipeline
  class ShutdownSignal; end

  def initialize(configstr)
    # hacks for now to parse a config string
    config = LogStash::Config::File.new(nil, configstr)
    agent = LogStash::Agent.new
    @inputs, @filters, @outputs = agent.instance_eval { parse_config(config) }

    @inputs.collect(&:register)
    @filters.collect(&:register)
    @outputs.collect(&:register)

    @input_to_filter = SizedQueue(16)
    @filter_to_output = SizedQueue(16)

    # If no filters, pipe inputs to outputs
    if @filters.empty?
      input_to_filter = filter_to_output
    end
  end

  def run
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

    # Now monitor input threads state
    # if all inputs are terminated, send shutdown signal to @input_to_filter
  end

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
  end # def 

  def filterworker
    begin
      while true
        event << @input_to_filter
        break if event == :shutdown
        @filters.each do |filter|
          filter.filter(event)
        end
        next if event.cancelled?
        @filter_to_output << event
      end
    rescue => e
      @logger.error("Exception in plugin #{plugin.class}",
                    "plugin" => plugin.inspect, "exception" => e)
    end
    @filters.each(&:teardown)
  end # def filterworker

  def outputworker
    begin
      while true
        event << @filter_to_output
        break if event == :shutdown
        @outputs.each do |output|
          output.receive(event)
        end
      end
    rescue => e
      @logger.error("Exception in plugin #{plugin.class}",
                    "plugin" => plugin.inspect, "exception" => e)
    end
    @outputs.each(&:teardown)
  end # def filterworker
end # class Pipeline

def twait(thread)
  begin
    puts :waiting => thread[:name]
    thread.join
    puts :donewaiting => thread[:name]
  rescue => e
    puts thread => e
  end
end

def shutdown(input, filter, output)
  input.each do |i|
    i.raise("SHUTDOWN")
  end

  #filter.raise("SHUTDOWN")
  #twait(filter)
  output.raise("SHUTDOWN")
  twait(output)
end

trap("INT") do
  puts "SIGINT"; shutdown(input_threads, filter_thread, output_thread)
  exit 1
end


