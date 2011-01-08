require "logstash/namespace"
require "logstash/logging"

class LogStash::Filters::Base
  attr_accessor :logger

  public
  def initialize(config = {})
    @logger = LogStash::Logger.new(STDERR)
    @config = config
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
