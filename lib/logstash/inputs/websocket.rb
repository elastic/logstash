# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Read events over the websocket protocol.
class LogStash::Inputs::Websocket < LogStash::Inputs::Base
  config_name "websocket"
  milestone 1

  default :codec, "json"

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
    require "ftw"
  end # def register

  public
  def run(output_queue)
    # TODO(sissel): Implement server mode.
    agent = FTW::Agent.new
    begin
      websocket = agent.websocket!(@url)
      websocket.each do |payload|
        @codec.decode(payload) do |event|
          decorate(event)
          output_queue << event
        end
      end
    rescue => e
      @logger.warn("websocket input client threw exception, restarting",
                   :exception => e)
      sleep(1)
      retry
    end # begin
  end # def run

end # class LogStash::Inputs::Websocket
