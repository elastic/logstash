require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Onstomp < LogStash::Outputs::Base
  config_name "onstomp"


  # The address of the STOMP server.
  config :host, :validate => :string

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
  config :destination, :validate => :string

  # Enable debugging output?
  config :debug, :validate => :boolean, :default => false

  public
  def register
    require "onstomp"
    @client = OnStomp::Client.new("stomp://#{@host}:#{@port}", :login => @user, :passcode => @password.value)
  end # def register

  public
  def receive(event)
    @client.connect
    @logger.debug(["stomp sending event", { :host => @host, :event => event }])
    @client.send(event.sprintf(@destination), event.to_json)
    @client.disconnect # http://mdvlrb.com/onstomp/file.UserNarrative.html#What_Really_Goes_Down_when_you__disconnect
  end # def receive
end # class LogStash::Outputs::Onstomp

