require "logstash/namespace"
require "logstash/event"
require "logstash/logging"
require "uri"

class LogStash::Inputs::Base
  def initialize(url, type, config={}, &block)
    @logger = LogStash::Logger.new(STDERR)
    @url = url
    @url = URI.parse(url) if url.is_a? String
    @config = config
    @callback = block
    @type = type
    @tags = []
  end

  def register
    raise "#{self.class}#register must be overidden"
  end

  def tag(newtag)
    @tags << newtag
  end

  def receive(event)
    @logger.debug(["Got event", { :url => @url, :event => event }])
    # Only override the type if it doesn't have one
    event.type = @type if !event.type 
    event.tags |= @tags # set union
    @callback.call(event)
  end
end # class LogStash::Inputs::Base
