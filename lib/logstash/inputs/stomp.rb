require "logstash/inputs/base"
require "logstash/namespace"

# TODO(sissel): This class doesn't work yet in JRuby. Google for
# 'execution expired stomp jruby' and you'll find the ticket.

# Stream events from a STOMP broker.
#
# TODO(sissel): Include info on where to learn about STOMP
class LogStash::Inputs::Stomp < LogStash::Inputs::Base
  config_name "stomp"

  # The address of the STOMP server.
  config :host, :validate => :string

  # The port to connet to on your STOMP server.
  config :port, :validate => :number, :default => 61613

  # The username to authenticate with.
  config :user, :validate => :string, :default => ""

  # The password to authenticate with.
  config :password, :validate => :password, :default => ""

  # The destination to read events from.
  #
  # Example: "/topic/logstash"
  config :destination, :validate => :string

  # Enable debugging output?
  config :debug, :validate => :boolean, :default => false

  public
  def register
    require "stomp"

    if @destination == "" or @destination.nil?
      @logger.error("No destination path given for stomp")
      return
    end

    begin
      @client = Stomp::Client.new(@user, @password, @host, @port)
    rescue Errno::ECONNREFUSED
      @logger.error("Connection refused to #{@host}:#{@port}...")
      # TODO(sissel): Retry?
    end
  end # def register

  def run(queue)
    @client.subscribe(@destination) do |msg|
      @logger.debug(["Got message from stomp", { :msg => msg }])
      #event = LogStash::Event.from_json(message.body)
      #queue << event
    end
  end # def run
end # class LogStash::Inputs::Stomp
