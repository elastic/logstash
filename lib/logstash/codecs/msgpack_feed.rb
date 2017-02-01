# encoding: utf-8
require "logstash/codecs/base"

class LogStash::Codecs::MsgpackFeed < LogStash::Codecs::Base
  config_name "msgpack_feed"

  milestone 1

  config :format, :validate => :string, :default => nil

  def initialize(params={})
    super(params)
    @unpacker = MessagePack::Unpacker.new
  end

  public
  def register
    require "msgpack"
  end

  public
  def decode(data)
    begin
      @unpacker.feed_each(data) do |rawevent|
        event = LogStash::Event.new(rawevent)
        event["tags"] ||= []
        if @format
          event["message"] ||= event.sprintf(@format)
        end
        yield event
      end
    rescue => e
      # Treat as plain text and try to do the best we can with it?
      @logger.warn("Trouble parsing msgpack input, falling back to plain text",
                   :input => data, :exception => e)
      event = LogStash::Event.new
      event["message"] = data.encode('utf-8', 'binary', :invalid => :replace,
                                                        :replace => ' ')
      event["tags"] ||= []
      event["tags"] << "_msgpackparsefailure"
      yield event
    end
  end # def decode
end # class LogStash::Codecs::MsgpackFeed
