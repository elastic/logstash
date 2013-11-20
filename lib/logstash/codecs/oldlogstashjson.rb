# encoding: utf-8
require "logstash/codecs/base"

class LogStash::Codecs::OldLogStashJSON < LogStash::Codecs::Base
  config_name "oldlogstashjson"
  milestone 1

  # Map from v0 name to v1 name.
  # Note: @source is gone and has no similar field.
  V0_TO_V1 = {"@timestamp" => "@timestamp", "@message" => "message",
              "@tags" => "tags", "@type" => "type",
              "@source_host" => "host", "@source_path" => "path"}

  public
  def decode(data)
    obj = JSON.parse(data.force_encoding("UTF-8"))

    h  = {}

    # Convert the old logstash schema to the new one.
    V0_TO_V1.each do |key, val|
      h[val] = obj[key] if obj.include?(key)
    end

    h.merge!(obj["@fields"]) if obj["@fields"].is_a?(Hash)
    yield LogStash::Event.new(h)
  end # def decode

  public
  def encode(data)
    h  = {}

    h["@timestamp"] = data["@timestamp"]
    h["@message"] = data["message"] if data.include?("message")
    h["@source_host"] = data["source_host"] if data.include?("source_host")
    # Convert the old logstash schema to the new one.
    basics = %w(@timestamp @message @source_host @source_path @source
                @tags @type)
    basics.each do |key|
      h[key] = data[key] if data.include?(key)
    end

    h.merge!(data["@fields"]) if data["@fields"].is_a?(Hash)
    @on_event.call(h.to_json)
  end # def encode

end # class LogStash::Codecs::OldLogStashJSON
