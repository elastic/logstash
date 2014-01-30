# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Stdout < LogStash::Outputs::Base
  begin
     require "ap"
  rescue LoadError
  end

  config_name "stdout"
  milestone 3
  
  default :codec, "line"

  # Enable debugging. Tries to pretty-print the entire event object.
  config :debug, :validate => :boolean, :default => false, :deprecated => "This setting has no effect. Please use `codec => rubydebug` if you wish to have the original behavior this setting provided."

  public
  def register
    @codec.on_event do |event|
      $stdout.write(event)
    end
  end

  def receive(event)
    return unless output?(event)
    if event == LogStash::SHUTDOWN
      finished
      return
    end
    @codec.encode(event)
  end

end # class LogStash::Outputs::Stdout
