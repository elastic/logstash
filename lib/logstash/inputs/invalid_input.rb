# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

class LogStash::Inputs::InvalidInput < LogStash::Inputs::Base
  config_name "invalid_input"
  milestone 1

  public
  def register; end

  def run(queue)
    event = LogStash::Event.new("message" =>"hello world 1 ÅÄÖ \xED")
    decorate(event)
    queue << event
    loop do; sleep(1); end
  end
end
