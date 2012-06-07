require "logstash/namespace"
require "logstash/event"
require "logstash/plugin"
require "logstash/logging"
require "logstash/config/mixin"
require "logstash/inputs/base"

# This is the base class for logstash inputs.
class LogStash::Inputs::Threadable < LogStash::Inputs::Base

  # Set this to the number of threads you want this input to spawn.
  # This is the same as declaring the input multiple times
  config :threads, :validate => :number, :default => 1
 
  attr_accessor :threadable

  def initialize(params)
    super
    @threadable = true
  end

end # class LogStash::Inputs::Threadable
