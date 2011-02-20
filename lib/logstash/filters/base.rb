require "logstash/namespace"
require "logstash/logging"
require "logstash/config/mixin"

class LogStash::Filters::Base
  include LogStash::Config::Mixin

  attr_accessor :logger

  config_name "filter"
  config :type => :string

  public
  def initialize(params)
    @logger = LogStash::Logger.new(STDERR)
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
  def filter(event)
    raise "#{self.class}#filter must be overidden"
  end # def filter

  public
  def add_config(type, typeconfig)
    if @config.include?(type)
      @config[type].merge!(typeconfig)
    else
      @config[type] = typeconfig
    end
  end # def add_config
end # class LogStash::Filters::Base
