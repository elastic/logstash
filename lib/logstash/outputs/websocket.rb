require "logstash/outputs/base"
require "em-websocket" # rubygem 'em-websocket'

class LogStash::Outputs::Websocket < LogStash::Outputs::Base
  def initialize(url, config={}, &block)
    super
  end

  def register
    @channel = EventMachine::Channel.new
    host = (@url.host or "0.0.0.0")
    port = (@url.port or 3000)
    EventMachine::WebSocket.start(:host => host, :port => port) do |ws|
      ws.onopen do
        sid = @channel.subscribe do |msg| 
          ws.send msg
        end
        ws.onclose do
          @channel.unsubscribe(sid)
        end # ws.onclose
      end # ws.onopen
    end
  end # def register

  def receive(event)
    @channel.push event.to_json
  end # def event
end # class LogStash::Outputs::Websocket
