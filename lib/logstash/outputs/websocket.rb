require "logstash/outputs/base"
require "em-websocket" # rubygem 'em-websocket'

class LogStash::Outputs::Websocket < LogStash::Outputs::Base
  def initialize(url, config={}, &block)
    super
  end

  def register
    @channel = EventMachine::Channel.new
    @subscribers = 0
    host = (@url.host or "0.0.0.0")
    port = (@url.port or 3000)
    EventMachine::WebSocket.start(:host => host, :port => port) do |ws|
      ws.onopen do
        @subscribers += 1
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

  def receive(event)
    # Only publish the event to websockets if there are subscribers
    # TODO(sissel): send a patch to eventmachine to fix this.
    if @subscribers > 0
      @channel.push event.to_json
    end
  end # def event
end # class LogStash::Outputs::Websocket
