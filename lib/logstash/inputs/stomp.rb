require "logstash/inputs/base"
require "logstash/namespace"

# TODO(sissel): This class doesn't work yet in JRuby. Haven't debugged it much.

class LogStash::Inputs::Stomp < LogStash::Inputs::Base
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
    @user ||= ''
    @password ||= ''
  end # def initialize

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
