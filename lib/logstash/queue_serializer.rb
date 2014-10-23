# encoding: utf-8
require "logstash/json"
require "msgpack"

# pluggable serializer for the persistent queue

class LogStash::JsonSerializer
  NL = "\n".freeze

  # @param event [LogStash::Event] the event to serialize
  # @return [String] the serialized event or nil to skip persistence
  def serialize(event)
    # exclude non LogStash::Event like the LogStash::ShutdownEvent and LogStash::FlushEvent
    return nil unless event.is_a?(LogStash::Event)

    event.to_json + NL + LogStash::Json.dump(event.metadata)
  end

  # @param data [String] searialized string data to deserialize
  # @return [LogStash::Event] the deserialzed event
  def deserialize(data)
    event, metadata = data.split(NL).map{|o| LogStash::Json.load(o)}
    LogStash::Event.new(event.merge({"@metadata" => metadata}))
  end
end
