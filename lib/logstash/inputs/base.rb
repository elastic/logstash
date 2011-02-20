require "logstash/namespace"
require "logstash/event"
require "logstash/logging"
require "logstash/config/mixin"
require "uri"

class LogStash::Inputs::Base
  include LogStash::Config::Mixin
  attr_accessor :logger

  config_name "input"

  # Define the basic config
  config :tag => (lambda do |value|
    p :tag => value
    re = /^[A-Za-z0-9_]+$/
    value.each do |v|
      if v !~ re
        return [false, "Tag '#{v}' does not match #{re}"]
      end # check 'v'
    end # value.each 
    return true
  end) # config :tag

  config :type => (lambda do |value|
    if value.size > 1
      return [false, "Type must be a single value, got #{value.inspect}, expected (for example) only #{value[0,1].inspect}"]
    end
    return true
  end) # config :type

  public
  def initialize(params)
    @logger = LogStash::Logger.new(STDERR)
    #@output_queue = output_queue
    if !self.class.validate(params)
      @logger.error "Config validation failed."
      exit 1
    end
  end # def initialize

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def tag(newtag)
    @tags << newtag
  end # def tag

  public
  def receive(event)
    @logger.debug(["Got event", { :url => @url, :event => event }])
    # Only override the type if it doesn't have one
    event.type = @type if !event.type 
    event.tags |= @tags # set union
    @callback.call(event)
  end # def receive
end # class LogStash::Inputs::Base
