require "json"
require "logstash/time"
require "uri"

# General event type. Will expand this in the future.
module LogStash; class Event
  def initialize(data=Hash.new)
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
  def source=(val) 
    if val.is_a?(URI)
      @data["@source"] = val.to_s
      @data["@source_host"] = val.host
      @data["@source_path"] = val.path
    else
      @data["@source"] = val
    end
  end # def source=

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

  def overwrite(event)
    @data = event.to_hash
  end

  def include?(key); return @data.include?(key) end

  # Append an event to this one.
  def append(event)
    self.message += "\n" + event.message 
    self.tags |= event.tags

    # Append all fields
    event.fields.each do |name, value|
      if self.fields.include?(name)
        puts "Merging field #{name}"
        self.fields[name] |= value
      else
        puts "Setting field #{name}"
        self.fields[name] = value
      end
    end # event.fields.each
  end
end; end # class LogStash::Event
