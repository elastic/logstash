require "logstash/namespace"
require "logstash/logging"

class LogStash::Filters::Base
  def initialize(config = {})
    @logger = LogStash::Logger.new(STDERR)
    @config = config
  end # def initialize

  def register
    throw "#{self.class}#register must be overidden"
  end # def register

  def filter(event)
    throw "#{self.class}#filter must be overidden"
  end # def filter
end # class LogStash::Filters::Base
