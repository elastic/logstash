require "logstash/namespace"
require "logstash/outputs/base"

# TODO(sissel): THIS IS NOT SUPPORTED IN JRUBY YET
class LogStash::Outputs::Websocket < LogStash::Outputs::Base

  config_name "websocket"
  plugin_status "experimental"

  # The address to serve websocket data from
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to serve websocket data from
  config :port, :validate => :number, :default => 3232

  public
  def register
    require "em-websocket" # rubygem 'em-websocket'
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
    return unless output?(event)

    # Only publish the event to websockets if there are subscribers
    # TODO(sissel): send a patch to eventmachine to fix this.
    if @subscribers > 0
      @logger.info("Sending event to websocket.")
      @channel.push event.to_json
    end
  end # def receive
end # class LogStash::Outputs::Websocket
