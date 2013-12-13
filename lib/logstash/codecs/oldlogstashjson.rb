# encoding: utf-8
require "logstash/codecs/base"

class LogStash::Codecs::OldLogStashJSON < LogStash::Codecs::Base
  config_name "oldlogstashjson"
  milestone 2

  # Map from v0 name to v1 name.
  # Note: @source is gone and has no similar field.
  V0_TO_V1 = {"@timestamp" => "@timestamp", "@message" => "message",
              "@tags" => "tags", "@type" => "type",
              "@source_host" => "host", "@source_path" => "path"}

  public
  def decode(data)
    begin
      obj = JSON.parse(data.force_encoding("UTF-8"))
    rescue JSON::ParserError => e
      @logger.info("JSON parse failure. Falling back to plain-text", :error => e, :data => data)
      yield LogStash::Event.new("message" => data)
      return
    end

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

    # Convert the new logstash schema to the old one.
    V0_TO_V1.each do |key, val|
      h[key] = data[val] if data.include?(val)
    end

    data.to_hash.each do |field, val|
      # TODO: might be better to V1_TO_V0 = V0_TO_V1.invert during
      # initialization than V0_TO_V1.has_value? within loop
      next if field == "@version" or V0_TO_V1.has_value?(field)
      h["@fields"] = {} if h["@fields"].nil?
      h["@fields"][field] = val
    end

    # Tack on a \n because JSON outputs 1.1.x had them.
    @on_event.call(h.to_json + "\n")
  end # def encode

end # class LogStash::Codecs::OldLogStashJSON
