require "logstash/codecs/base"
require "msgpack"

class LogStash::Codecs::Msgpack < LogStash::Codecs::Base
  config_name "json"

  plugin_status "experimental"

  config :format, :validate => :string, :default => nil

  public
  def decode(data)
    begin
      # Msgpack does not care about UTF-8
      event = LogStash::Event.new(MessagePack.unpack(raw))
      event["tags"] ||= []
      if @format
        event.message ||= event.sprintf(@format)
      end
    rescue => e
      ## TODO(sissel): Instead of dropping the event, should we treat it as
      ## plain text and try to do the best we can with it?
      @logger.warn("Trouble parsing msgpack input, falling back to plain text",
                   :input => raw, :exception => e)
      event.message = raw
      event["tags"] ||= []
      event["tags"] << "_msgpackparsefailure"
    end
    yield event
  end # def decode

  public
  def encode(event)
    @on_event.call event.to_hash.to_msgpack
  end # def encode

end # class LogStash::Codecs::Msgpack
