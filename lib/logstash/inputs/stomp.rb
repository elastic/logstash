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
  config :destination, :validate => :string, :required => true

  # Enable debugging output?
  config :debug, :validate => :boolean, :default => false

  public
  def initialize(params)
    super

    @format ||= "json_event"
  end

  public
  def register
    require "stomp"

    begin
      @client = Stomp::Client.new(@user, @password.value, @host, @port)
      @stomp_url = "stomp://#{@user}:#{@password}@#{@host}:#{@port}/#{@destination}"
    rescue Errno::ECONNREFUSED => e
      @logger.error("Connection refused to #{@host}:#{@port}...")
      raise e
    end
  end # def register

  def run(queue)
    @client.subscribe(@destination) do |msg|
      e = to_event(message.body, @stomp_url)
      if e
        queue << e
      end
    end
  end # def run
end # class LogStash::Inputs::Stomp
