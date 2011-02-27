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
      ap event.to_hash
    else
      puts event.to_s
    end
  end # def event
end # class LogStash::Outputs::Stdout
