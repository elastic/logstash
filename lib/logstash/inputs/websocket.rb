require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Read events over the websocket protocol.
class LogStash::Inputs::Websocket < LogStash::Inputs::Base
  config_name "websocket"
  plugin_status "experimental"

  # The url to connect to or serve from
  config :url, :validate => :string, :default => "0.0.0.0"

  # Operate as a client or a server.
  #
  # Client mode causes this plugin to connect as a websocket client
  # to the URL given. It expects to receive events as websocket messages.
  #
  # (NOT IMPLEMENTED YET) Server mode causes this plugin to listen on
  # the given URL for websocket clients. It expects to receive events
  # as websocket messages from these clients.
  config :mode, :validate => [ "server", "client" ], :default => "client"

  def register
    @format ||= "json_event"
    require "ftw"
  end # def register

  public
  def run(output_queue)
    # TODO(sissel): Implement server mode.
    LogStash::Util::set_thread_name("<websocket")
    agent = FTW::Agent.new
    begin
      websocket = agent.websocket!(@url)
      websocket.each do |payload|
        event = to_event(payload, @url)
        output_queue << event
      end
    rescue => e
      @logger.warn("websocket input client threw exception, restarting",
                   :exception => e)
      sleep(1)
      retry
    end # begin
  end # def run

end # class LogStash::Inputs::Udp
