# encoding: utf-8
require "logstash/codecs/base"
require "logstash/util/charset"

# This codec handles fluentd's msgpack schema.
#
# For example, you can receive logs from fluent-logger-ruby with:
#
#     input {
#       tcp {
#         codec => fluent
#         port => 4000
#       }
#     }
#
# And from your ruby code in your own application:
#
#     logger = Fluent::Logger::FluentLogger.new(nil, :host => "example.log", :port => 4000)
#     logger.post("some_tag", { "your" => "data", "here" => "yay!" })
#
# Notes:
#
# * the fluent uses a second-precision time for events, so you will never see
#   subsecond precision on events processed by this codec.
#
class LogStash::Codecs::Fluent < LogStash::Codecs::Base
  config_name "fluent"
  milestone 1

  public
  def register
    require "msgpack"
    @decoder = MessagePack::Unpacker.new
  end

  public
  def decode(data)
    @decoder.feed(data)
    @decoder.each do |tag, epochtime, map|
      event = LogStash::Event.new(map.merge(
        "@timestamp" => Time.at(epochtime),
        "tags" => tag
      ))
      yield event
    end
  end # def decode

  public
  def encode(event)
    tag = event["tags"] || "log"
    epochtime = event["@timestamp"].to_i
    @on_event.call(MessagePack.pack([ tag, epochtime, event.to_hash ]))
  end # def encode

end # class LogStash::Codecs::Fluent
