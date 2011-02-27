require "ap"
require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Stdout < LogStash::Outputs::Base

  config_name "stdout"
  config :debug, :validate => :boolean

  public
  def initialize(params)
    super

    #@debug ||= false
  end

  public
  def register
    # nothing to do
  end

  public
  def receive(event)
    if @debug
      ap event
    else
      puts event
    end
  end # def event
end # class LogStash::Outputs::Stdout
