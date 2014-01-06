# encoding: utf-8
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

  get "/" do
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

