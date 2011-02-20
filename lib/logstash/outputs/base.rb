require "cgi"
require "logstash/event"
require "logstash/logging"
require "logstash/namespace"
require "logstash/config/mixin"
require "uri"

class LogStash::Outputs::Base
  include LogStash::Config::Mixin

  attr_accessor :logger

  config_name "output"

  public
  def initialize(params)
    @logger = LogStash::Logger.new(STDOUT)
    if !self.class.validate(params)
      @logger.error "Config validation failed."
      exit 1
    end

    params.each do |key, value|
      validator = self.class.validator_find(key)
      #value = params[key]
      @logger.info("Setting: @#{key} = #{value.inspect}")
      self.instance_variable_set("@#{key}", value)
    end
  end

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def receive(event)
    raise "#{self.class}#receive must be overidden"
  end # def receive
end # class LogStash::Outputs::Base
