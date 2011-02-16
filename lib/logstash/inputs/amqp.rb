require "amqp" # rubygem 'amqp'
require "logstash/inputs/base"
require "logstash/namespace"
require "mq" # rubygem 'amqp'
require "uuidtools" # rubygem 'uuidtools'
require "cgi"

class LogStash::Inputs::Amqp < LogStash::Inputs::Base
  MQTYPES = [ "fanout", "queue", "topic" ]

  public
  def initialize(url, type, config={}, &block)
    super

    @mq = nil

    # Handle path /<vhost>/<type>/<name> or /<type>/<name>
    # vhost allowed to contain slashes
    if @url.path =~ %r{^/((.*)/)?([^/]+)/([^/]+)}
      unused, @vhost, @mqtype, @name = $~.captures
    else
      raise "amqp urls must have a path of /<type>/name or /vhost/<type>/name where <type> is #{MQTYPES.join(", ")}"
    end

    if !MQTYPES.include?(@mqtype)
      raise "Invalid type '#{@mqtype}' must be one of #{MQTYPES.join(", ")}"
    end
  end # def initialize

  public
  def register
    @logger.info("Registering input #{@url}")
    query_args = @url.query ? CGI.parse(@url.query) : {}
    amqpsettings = {
      :vhost => (@vhost or "/"),
      :host => @url.host,
      :port => (@url.port or 5672),
      :logging => true
    }
    amqpsettings[:user] = @url.user if @url.user
    amqpsettings[:pass] = @url.password if @url.password
    amqpsettings[:logging] = query_args.include? "debug"
    @logger.debug("Connecting with AMQP settings #{amqpsettings.inspect} to set up #{@mqtype.inspect} queue #{@name.inspect}")
    @amqp = AMQP.connect(amqpsettings)
    @mq = MQ.new(@amqp)
    @target = nil

    @target = @mq.queue(UUIDTools::UUID.timestamp_create)
    case @mqtype
      when "fanout"
        #@target.bind(MQ.fanout(@url.path, :durable => true))
        @target.bind(@mq.fanout(@name))
      when "direct"
        @target.bind(@mq.direct(@name))
      when "topic"
        @target.bind(@mq.topic(@name))
    end # case @mqtype

    @target.subscribe(:ack => true) do |header, message|
      event = LogStash::Event.from_json(message)
      receive(event)
      header.ack
    end
  end # def register
end # class LogStash::Inputs::Amqp
