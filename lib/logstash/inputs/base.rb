require "logstash/namespace"
require "logstash/event"
require "logstash/logging"
require "logstash/config/mixin"
require "uri"

class LogStash::Inputs::Base
  include LogStash::Config::Mixin
  attr_accessor :logger

  config_name "input"
  config :type => :string

  config :tag => (lambda do |value|
    re = /^[A-Za-z0-9_]+$/
    value.each do |v|
      if v !~ re
        return [false, "Tag '#{v}' does not match #{re}"]
      end # check 'v'
    end # value.each 
    return true
  end) # config :tag


  public
  def initialize(params)
    @logger = LogStash::Logger.new(STDERR)
    config_init(params)
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
