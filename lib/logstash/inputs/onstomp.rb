require "logstash/inputs/base"
require "logstash/namespace"

class LogStash::Inputs::Onstomp < LogStash::Inputs::Base
  config_name "onstomp"

  # The address of the STOMP server.
  config :host, :validate => :string, :default => "localhost"

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

  private
  def connect
    begin
      @client.connect
      @logger.info("Connected to stomp server") if @client.connected?
    rescue => e
      @logger.debug("Failed in connect : #{e}")
    end
  end

  public
  def register
    require "onstomp"

    @client = OnStomp::Client.new("stomp://#{@host}:#{@port}", :login => @user, :passcode => @password.value)
    @stomp_url = "stomp://#{@user}:#{@password}@#{@host}:#{@port}/#{@destination}"
    connect
  end # def register

  def run(output_queue)
    @client.subscribe(@destination) do |msg|
      e = to_event(msg.body, @stomp_url)
      if e
        output_queue << e
      end
    end
      
    while true 
      # stay subscribed to the destination
    end

    raise "disconnected from stomp server"
  end # def run
end # class LogStash::Inputs::Onstomp

