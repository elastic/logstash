require "logstash/inputs/base"
require "logstash/stomp/handler"

class LogStash::Inputs::Stomp < LogStash::Inputs::Base

  class InputHandler < LogStash::Stomp::Handler
    def receive_msg(message)
      super

      unless message.command == "CONNECTED"
        event = LogStash::Event.from_json(message.body)
        @input.receive(event)
      end
    end # def receive_msg
  end # class StompHandler

  def initialize(url, config={}, &block)
    super

    @logger.debug(["Connecting", { :url => @url }])
  end # def initialize

  def register
    @logger.info(["Registering input", { :url => @url}])
    EventMachine::connect(@url.host, @url.port, InputHandler, self, @logger, @url)
  end # def register
end # class LogStash::Inputs::Amqp
