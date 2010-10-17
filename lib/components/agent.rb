
require "eventmachine"
require "eventmachine-tail"

class Reader < EventMachine::FileTail
  def initialize(path, agent)
    super(path)
    @agent = agent
    @buffer = BufferedTokenizer.new  # From eventmachine
  end

  def receive_data(data)
    # TODO(sissel): Support multiline log data
    @buffer.extract(data).each do |line|
      # Package it up into an event object before passing it along.
      @agent.process(path, line)
    end
  end # def receive_data
end # class Reader

# Collect logs, ship them out.
module LogStash; module Components; class Agent
  attr_reader :config

  def initialize(config)
    @config = config
    # Config should have:
    # - list of logs to monitor
    #   - log config
    # - where to ship to
  end # def initialize

  # Register any event handlers with EventMachine
  # Technically, this agent could listen for anything (files, sockets, amqp,
  # stomp, etc).
  def register
    @config["logs"].each do |path|
      EventMachine::FileGlobWatchTail.new(path, Reader, interval=60,
                                          exclude=[], agent=self)
    end # each log
  end # def register

  # Process a message
  def process(source, message)
    puts "#{source}: #{message}"
  end # def process
end; end; end; # class LogStash::Components::Agent
