require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Stdout < LogStash::Outputs::Base

  config_name "stdout"
  config :debug => :boolean

  public
  def initialize(*args)
    super

  end # def register

  public
  def receive(event)
    if debug?
      ap event
    else
      puts event
    end
  end # def event

  public
  def debug?
    return @debug
  end
end # class LogStash::Outputs::Stdout
