require "em-websocket" # rubygem 'em-websocket'
require "logstash/namespace"
require "logstash/outputs/base"

class LogStash::Outputs::Websocket < LogStash::Outputs::Base
  public
  def register
    @channel = EventMachine::Channel.new
    @subscribers = 0
    @url.host = (@url.host or "0.0.0.0")
    @url.port = (@url.port or 3232)
    @logger.info("Registering websocket on #{@url}")
    EventMachine::WebSocket.start(:host => @url.host, :port => @url.port) do |ws|
      ws.onopen do
        @subscribers += 1
        @logger.info("New #{self.class.name} connection")
        sid = @channel.subscribe do |msg| 
          ws.send msg
        end
        ws.onclose do
          @channel.unsubscribe(sid)
          @subscribers -= 1
        end # ws.onclose
      end # ws.onopen
    end
  end # def register

  public
  def receive(event)
    # Only publish the event to websockets if there are subscribers
    # TODO(sissel): send a patch to eventmachine to fix this.
    if @subscribers > 0
      @logger.info("Sending event to websocket.")
      @channel.push event.to_json
    end
  end # def receive
end # class LogStash::Outputs::Websocket
