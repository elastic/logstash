require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Stdout < LogStash::Outputs::Base
  public
  def register
    # nothing to do
  end # def register

  public
  def receive(event)
    puts event
  end # def event
end # class LogStash::Outputs::Stdout
