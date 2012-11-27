require "logstash/namespace"
require "logstash/outputs/websocket"
require "sinatra/base"
require "rack/handler/ftw" # from ftw
require "ftw/websocket/rack" # from ftw

class LogStash::Outputs::WebSocket::App < Sinatra::Base
  def initialize(pubsub, logger)
    @pubsub = pubsub
    @logger = logger
  end

  set :reload_templates, false

  helpers do
    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      auth = Rack::Auth::Basic::Request.new(request.env)
      auth.provided? && auth.basic? && auth.credentials && auth.credentials == ['admin', 'admin']
    end
  end


  get "/" do
    protected!
    # TODO(sissel): Support filters/etc.
    ws = ::FTW::WebSocket::Rack.new(env)
    @logger.debug("New websocket client")
    stream(:keep_open) do |out|
      @pubsub.subscribe do |event|
        ws.publish(event)
      end # pubsub
    end # stream

    ws.rack_response
  end # get /
end # class LogStash::Outputs::WebSocket::App

