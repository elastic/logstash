require "logstash/namespace"
require "logstash/logging"

class LogStash::Filters::Base
  def initialize(config = {})
    @logger = LogStash::Logger.new(STDERR)
    @config = config
  end # def initialize

  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  def filter(event)
    raise "#{self.class}#filter must be overidden"
  end # def filter

  def add_config(type, typeconfig)
    if @config.include?(type)
      @config[type].merge!(typeconfig)
    else
      @config[type] = typeconfig
    end
  end
end # class LogStash::Filters::Base
