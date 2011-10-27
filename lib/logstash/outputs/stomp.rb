require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Stomp < LogStash::Outputs::Base
  config_name "stomp"


  # The address of the STOMP server.
  config :host, :validate => :string, :required => true

  # The port to connect to on your STOMP server.
  config :port, :validate => :number, :default => 61613

  # The username to authenticate with.
  config :user, :validate => :string, :default => ""

  # The password to authenticate with.
  config :password, :validate => :password, :default => ""

  # The destination to read events from. Supports string expansion, meaning
  # %{foo} values will expand to the field value.
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
      @logger.debug("Failed to connect to stomp server, will retry",
                    :exception => e, :backtrace => e.backtrace)
      sleep 2
      retry
    end
  end


  public
  def register
    require "onstomp"
    @client = OnStomp::Client.new("stomp://#{@host}:#{@port}", :login => @user, :passcode => @password.value)

    # Handle disconnects
    @client.on_connection_closed {
      connect
    }
    
    connect
  end # def register
  
  def receive(event)
      return unless output?(event)

      @logger.debug(["stomp sending event", { :host => @host, :event => event }])
      @client.send(event.sprintf(@destination), event.to_json)
  end # def receive
end # class LogStash::Outputs::Stomp

