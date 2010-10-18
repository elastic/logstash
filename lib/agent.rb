require "eventmachine"
require "eventmachine-tail"
require "logstash/namespace"
require "logstash/inputs"
require "logstash/outputs"
require "logstash/filters"

# Collect logs, ship them out.
class LogStash::Agent
  attr_reader :config

  def initialize(config)
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
    # Register input and output stuff
    if @config.include?("input")
      @config["input"].each do |url|
        input = LogStash::Inputs.from_url(url) { |event| receive(event) }
        input.register
        @inputs << input
      end # each input
    end

    if @config.include?("filter")
      @config["filter"].each do |name|
        filter = LogStash::Filters.from_name(name)
        filter.register
        @filters << filter
      end # each filter
    end

    if @config.include?("output")
      @config["output"].each do |url|
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
    output(event)
  end # def input
end # class LogStash::Components::Agent
