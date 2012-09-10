require "logstash/inputs/threadable"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# Generate random log events.
#
# The general intention of this is to test performance of plugins.
#
# An event is generated first
class LogStash::Inputs::Generator < LogStash::Inputs::Threadable
  config_name "generator"
  plugin_status "beta"

  # The message string to use in the event.
  #
  # If you set this to 'stdin' then this plugin will read a single line from
  # stdin and use that as the message string for every event.
  #
  # Otherwise, this value will be used verbatim as the event message.
  config :message, :validate => :string, :default => "Hello world!"

  # Set how many messages should be generated.
  #
  # The default, 0, means generate an unlimited number of events.
  config :count, :validate => :integer, :default => 0

  public
  def register
    @host = Socket.gethostname

    if @count.is_a?(Array)
      @count = @count.first
    end
  end # def register

  def run(queue)
    number = 0
    source = "generator://#{@host}/"

    if @message == "stdin"
      @logger.info("Generator plugin reading a line from stdin")
      @message = $stdin.readline
      @logger.debug("Generator line read complete", :message => @message)
    end

    while !finished? && (@count <= 0 || number < @count)
      event = to_event(@message, source)
      event["sequence"] = number
      number += 1
      queue << event
    end # loop
  end # def run

  public
  def teardown
    finished
  end # def teardown
end # class LogStash::Inputs::Stdin
