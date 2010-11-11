require "json"
require "logstash/time"

# General event type. Will expand this in the future.
module LogStash; class Event
  def initialize(data)
    @cancelled = false
    @data = {
      "@source" => "unknown",
      "@type" => nil,
      "@tags" => [],
      "@fields" => {},
    }.merge(data)

    if !@data.include?("@timestamp")
      @data["@timestamp"] = LogStash::Time.now.utc.to_iso8601
    end
  end # def initialize

  def self.from_json(json)
    return Event.new(JSON.parse(json))
  end # def self.from_json

  def cancel
    @cancelled = true
  end

  def cancelled?
    return @cancelled
  end

  def to_s
    return "#{timestamp} #{source}: #{message}"
  end # def to_s

  def timestamp; @data["@timestamp"]; end # def timestamp
  def timestamp=(val); @data["@timestamp"] = val; end # def timestamp=
  def source; @data["@source"]; end # def source
  def source=(val); @data["@source"] = val; end # def source=
  def message; @data["@message"]; end # def message
  def message=(val); @data["@message"] = val; end # def message=
  def type; @data["@type"]; end # def type
  def type=(val); @data["@type"] = val; end # def type=
  def tags; @data["@tags"]; end # def tags
  def tags=(val); @data["@tags"] = val; end # def tags=

  # field-related access
  def [](key); @data["@fields"][key] end # def []
  def []=(key, value); @data["@fields"][key] = value end # def []=
  def fields; return @data["@fields"] end # def fields
  
  def to_json; return @data.to_json end # def to_json

  def to_hash; return @data end # def to_hash

  def include?(key); return @data.include?(key) end
end; end # class LogStash::Event
