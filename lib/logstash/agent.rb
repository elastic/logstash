require "eventmachine"
require "eventmachine-tail"
require "logstash/namespace"
require "logstash/inputs"
require "logstash/outputs"
require "logstash/filters"
require "logstash/logging"

# Collect logs, ship them out.
class LogStash::Agent
  attr_reader :config

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
  protected
  def register
    # TODO(sissel): warn when no inputs and no outputs are defined.
    # TODO(sissel): Refactor this madness into a config lib

    # Register input and output stuff
    if @config.include?("inputs")
      inputs = @config["inputs"]
      inputs.each do |value|
        # If 'url' is an array, then inputs is a hash and the key is a tag
        if inputs.is_a?(Hash)
          tag, urls = value
        else
          tag = nil
          urls = value
        end

        # url could be a string or an array.
        urls = [urls] if !urls.is_a?(Array)

        urls.each do |url|
          @logger.debug("Using input #{url} with tag #{tag}")
          input = LogStash::Inputs.from_url(url) { |event| receive(event) }
          input.tag(tag) if tag
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
  end # def register

  public
  def run
    EventMachine.run do
      self.register
    end # EventMachine.run
  end # def run

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
end # class LogStash::Components::Agent
