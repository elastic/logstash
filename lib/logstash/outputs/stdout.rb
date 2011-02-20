require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Stdout < LogStash::Outputs::Base

  config_name "stdout"
  config :debug => :boolean

  public
  def initialize(*args)
    super

    @opts = {}
    if @url.path != "/"
      @opts = @url.path[1..-1].split(",")
    end
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
    return @opts.member?("debug")
  end
end # class LogStash::Outputs::Stdout
