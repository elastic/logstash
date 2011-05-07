require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Stomp < LogStash::Outputs::Base
  config_name "stomp"

  
  # The address of the STOMP server.
  config :host, :validate => :string

  # The port to connet to on your STOMP server.
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
    require "stomp"
    @client = Stomp::Client.new(@user, @password.value, @host, @port)
  end # def register

  public
  def receive(event)
    @logger.debug(["stomp sending event", { :host => @host, :event => event }])
    @client.publish(event.sprintf(@destination), event.to_json)
  end # def receive
end # class LogStash::Outputs::Stomp
