require "logstash/namespace"
require "logstash/outputs/base"

# TODO(sissel): THIS IS NOT SUPPORTED IN JRUBY YET
class LogStash::Outputs::WebSocket < LogStash::Outputs::Base
  config_name "websocket"
  plugin_status "experimental"

  # The address to serve websocket data from
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to serve websocket data from
  config :port, :validate => :number, :default => 3232

  public
  def register
    require "ftw"
    require "logstash/outputs/websocket/app"
    require "logstash/outputs/websocket/pubsub"
    @pubsub = LogStash::Outputs::WebSocket::Pubsub.new
    @pubsub.logger = @logger
    @server = Thread.new(@pubsub) do |pubsub|
      begin
        Rack::Handler::FTW.run(LogStash::Outputs::WebSocket::App.new(pubsub, @logger),
                               :Host => @host, :Port => @port)
      rescue => e
        @logger.error("websocket server failed", :exception => e)
        sleep 1
        retry
      end
    end
  end # def register

  public
  def receive(event)
    return unless output?(event)
    @pubsub.publish(event.to_json)
  end # def receive

end # class LogStash::Outputs::Websocket
