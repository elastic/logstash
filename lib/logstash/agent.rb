require "eventmachine"
require "eventmachine-tail"
require "logstash/filters"
require "logstash/inputs"
require "logstash/logging"
require "logstash/namespace"
require "logstash/outputs"

# Collect logs, ship them out.
class LogStash::Agent
  attr_reader :config
  attr_reader :inputs
  attr_reader :outputs
  attr_reader :filters

  def initialize(config)
    @logger = LogStash::Logger.new(STDERR)

    @config = config
    @outputs = []
    @inputs = []
    @filters = []
    # Config should have:
    # - list of logs to monitor
    #   - log config
    # - where to ship to
  end # def initialize

  # Register any event handlers with EventMachine
  # Technically, this agent could listen for anything (files, sockets, amqp,
  # stomp, etc).
  public
  def register
    # TODO(sissel): warn when no inputs and no outputs are defined.
    # TODO(sissel): Refactor this madness into a config lib
    
    if (["inputs", "outputs"] & @config.keys).length == 0
      $stderr.puts "No inputs or no outputs configured. This probably isn't what you want."
    end

    # Register input and output stuff
    if @config.include?("inputs")
      inputs = @config["inputs"]
      inputs.each do |value|
        # If 'url' is an array, then inputs is a hash and the key is the type
        if inputs.is_a?(Hash)
          type, urls = value
        else
          raise "config error, no type for url #{urls.inspect}"
        end

        # url could be a string or an array.
        urls = [urls] if !urls.is_a?(Array)

        urls.each do |url|
          @logger.debug("Using input #{url} of type #{type}")
          input = LogStash::Inputs.from_url(url, type) { |event| receive(event) }
          input.register
          @inputs << input
        end
      end # each input
    end

    if @config.include?("filters")
      filters = @config["filters"]
      filters.collect { |x| x.to_a[0] }.each do |filter|
        name, value = filter
        @logger.debug("Using filter #{name} => #{value.inspect}")
        filter = LogStash::Filters.from_name(name, value)
        filter.register
        @filters << filter
      end # each filter
    end

    if @config.include?("outputs")
      @config["outputs"].each do |url|
        @logger.debug("Using output #{url}")
        output = LogStash::Outputs.from_url(url)
        output.register
        @outputs << output
      end # each output
    end

    # Register any signal handlers
    sighandler
  end # def register

  public
  def run(&block)
    EventMachine.run do
      self.register
      yield if block_given?
    end # EventMachine.run
  end # def run

  public
  def stop
    # TODO(sissel): Stop inputs, fluch outputs, wait for finish,
    # then stop the event loop
    EventMachine.stop_event_loop
  end

  protected
  def filter(event)
    @filters.each do |f|
      # TODO(sissel): Add ability for a filter to cancel/drop a message
      f.filter(event)
      if event.cancelled?
        break
      end
    end
  end # def filter

  protected
  def output(event)
    @outputs.each do |o|
      o.receive(event)
    end # each output
  end # def output

  protected
  # Process a message
  def receive(event)
    filter(event)

    if !event.cancelled?
      output(event)
    end
  end # def input

  public
  def sighandler
    @sigchannel = EventMachine::Channel.new
    Signal.trap("USR1") do
      @sigchannel.push(:USR1)
    end

    @sigchannel.subscribe do |msg|
      case msg
      when :USR1
        counts = Hash.new { |h,k| h[k] = 0 }
        ObjectSpace.each_object do |obj|
          counts[obj.class] += 1
        end

        @logger.info("SIGUSR1 received. Dumping state")
        @logger.info("#{self.class.name} config")
        @logger.info(["  Inputs:", @inputs])
        @logger.info(["  Filters:", @filters])
        @logger.info(["  Outputs:", @outputs])

        @logger.info("Dumping counts of objects by class")
        counts.sort { |a,b| a[1] <=> b[1] or a[0] <=> b[0] }.each do |key, value|
          @logger.info("Class: [#{value}] #{key}")
        end
      end
    end
  end
end # class LogStash::Components::Agent
