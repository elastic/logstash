require "logstash/inputs/base"
require "logstash/namespace"
require 'pp'

class LogStash::Inputs::Stomp < LogStash::Inputs::Base
  config_name "stomp"

  # The address of the STOMP server.
  config :host, :validate => :string, :default => "localhost", :required => true

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
      @logger.debug("Connected to stomp server") if @client.connected?
    rescue => e
      @logger.debug("Failed to connect to stomp server, will retry", :exception => e, :backtrace => e.backtrace)
      sleep 2
      retry
    end
  end

  public
  def register
    require "onstomp"
    @client = OnStomp::Client.new("stomp://#{@host}:#{@port}", :login => @user, :passcode => @password.value)
    @stomp_url = "stomp://#{@user}:#{@password}@#{@host}:#{@port}/#{@destination}"
    
    # Handle disconnects 
    @client.on_connection_closed {
      connect
      subscription_handler # is required for re-subscribing to the destination
    }
    connect
  end # def register

  private
  def subscription_handler
    @client.subscribe(@destination) do |msg|
      e = to_event(msg.body, @stomp_url)
      @output_queue << e if e
    end

    while @client.connected?
      # stay subscribed
    end
  end

  public
  def run(output_queue)
    @output_queue = output_queue 
    subscription_handler
  end # def run
end # class LogStash::Inputs::Stomp

