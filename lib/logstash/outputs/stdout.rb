require "logstash/outputs/base"

class LogStash::Outputs::Stdout < LogStash::Outputs::Base
  def initialize(url, config={}, &block)
    super
  end

  def register
    # nothing to do
  end # def register

  def receive(event)
    puts event
  end # def event
end # class LogStash::Outputs::Stdout
