require "bunny" # rubygem 'bunny'
require "logstash/inputs/base"
require "logstash/namespace"
require "mq" # rubygem 'amqp'
#require "uuidtools" # rubygem 'uuidtools'
require "cgi"
require "uri"

class LogStash::Inputs::Amqp < LogStash::Inputs::Base
  MQTYPES = [ "fanout", "queue", "topic" ]

  config_name "amqp"
  #config "host" => (lambda do |value|
    ## Use URI to validate.
    #u = URI.parse("dummy:///")
    #begin
      #u.host = value
    #rescue => e
      #return false, "Invalid hostname #{value.inspect}"
    #end
    #return true
  #) # config "host"

  config :host => :string
  config :user => :string
  config :pass => :string
  config :exchange_type => :string
  config :name => :string
  config :vhost => :string
  config :durable => :boolean
  config :debug => :boolean


  public
  def initialize(params)
    super

    @mq = nil
    @debug ||= false
    @durable ||= false

    if !MQTYPES.include?(@exchange_type)
      raise "Invalid type '#{@exchange_type}' must be one of #{MQTYPES.join(", ")}"
    end
  end # def initialize

  public
  def register
    @logger.info("Registering input #{@url}")
    amqpsettings = {
      :vhost => (@vhost or "/"),
      :host => @host,
      :port => (@port or 5672),
    }
    amqpsettings[:user] = @user if @user
    amqpsettings[:pass] = @password if @password
    amqpsettings[:logging] = @debug
    @logger.debug("Connecting with AMQP settings #{amqpsettings.inspect} to set up #{@mqtype.inspect} queue #{@name.inspect}")
    @bunny = Bunny.new(amqpsettings)

    # TODO(sissel): Check for errors here.
    @bunny.start

    @queue = @bunny.queue(@name)
    exchange = @bunny.exchange(@name, :type => @exchange_type.to_sym)
    @queue.bind(exchange)
  end # def register

  def run(queue)
    loop do
      @queue.subscribe do |data|
        begin
          obj = JSON.parse(data[:payload])
        rescue => e
          @logger.error(["json parse error", { :exception => e }])
          raise e
        end

        queue << LogStash::Event.new(obj)
      end # @queue.subscribe
    end # loop
  end # def run
end # class LogStash::Inputs::Amqp
