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
# Forwarding data from the fluentd agents to the logstash is also possible.
#
# Logstash configuration:
#
#    input {
#      tcp {
#        codec => fluent
#        port => 4000
#      }
#    }
#
# Fluent configuration:
#
#    <source>
#      type tail
#      format none
#      path /var/log/syslog
#      tag syslog
#    </source>
#    <match syslog>
#      type out_forward
#      heartbeat_type tcp
#      <server>
#        name localhost
#        host localhost
#        port 4000
#        weight 100
#      </server>
#    </match>
#
# Notes:
#
# * heartbeat_type of the fluent's out_forward plugin must be set to tcp, although the default value is udp if using
#   logstash'es tcp input plugin
#
# * udp heartbeats are supported by the logstash fluent input plugin
#
# * the fluent uses a second-precision time for events, so you will never see
#   subsecond precision on events processed by this codec except the cases when
#   the @timestamp presents in the received message
#
class LogStash::Codecs::Fluent < LogStash::Codecs::Base
  config_name "fluent"
  milestone 1

  # Don't add fluent's tag to the event tags
  config :ignore_tag, :validate => :boolean, :default => false

  public
  def register
    require "msgpack"
    @decoder = MessagePack::Unpacker.new
    @payload_decoder = MessagePack::Unpacker.new
  end

  public
  def decode(data)
    @decoder.feed(data)
    @decoder.each do |obj|
      tag = obj[0]
      entries = obj[1]
      if entries.class == String # PackedForward
        @payload_decoder.feed_each(entries) do |epochtime, map|
          yield event(tag, epochtime, map)
        end
      elsif entries.class == Array # Forward
        entries.each do |epochtime, map|
          yield event(tag, epochtime, map)
        end
      else # Message [tag, timestamp, msg]
        yield event(tag, entries, obj[2])
      end
    end
  end # def decode

  public
  def encode(event)
    tag = (event["tags"][0] unless event["tags"].nil?) || "log"
    epochtime = event["@timestamp"].to_i
    # Time is not supported by MessagePack, so convert @timestamp to string
    msg = event.to_hash.merge({"@timestamp" => event["@timestamp"].iso8601(3)})
    @on_event.call(MessagePack.pack([ tag, epochtime, msg ]))
  end # def encode

  private
  def event(tag, epochtime, map)
    map["@timestamp"] = Time.at(epochtime).utc if map["@timestamp"].nil?

    event = LogStash::Event.new(map)
    event.tag(tag) unless @ignore_tag
    event
  end

end # class LogStash::Codecs::Fluent
