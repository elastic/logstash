require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Stomp < LogStash::Outputs::Base
  config_name "stomp"
  config :host, :validate => :string
  config :port, :validate => :number
  config :user, :validate => :string
  config :password, :validate => :string
  config :destination, :validate => :string
  config :debug, :validate => :boolean

  public
  def initialize(params)
    super

    @debug ||= false
    @port ||= 61613
  end # def initialize

  public
  def register
    require "stomp"
    @client = Stomp::Client.new(@user, @password, @host, @port)
  end # def register

  public
  def receive(event)
    @logger.debug(["stomp sending event", { :host => @host, :event => event }])
    @client.publish(@destination, event.to_json)
  end # def receive
end # class LogStash::Outputs::Stomp
