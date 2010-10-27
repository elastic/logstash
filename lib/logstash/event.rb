require "json"
require "logstash/time"

# General event type. Will expand this in the future.
module LogStash; class Event
  def initialize(data)
    @cancelled = false
    @data = data
    if !@data.include?("timestamp")
      @data["timestamp"] = LogStash::Time.now.utc.to_iso8601
    end
  end # def initialize

  def self.from_json(json)
    return Event.new(JSON.parse(json))
  end # def self.from_json

  def to_json
    return @data.to_json
  end

  def cancel
    @cancelled = true
  end

  def cancelled?
    return @cancelled
  end

  def to_s
    return "#{timestamp} #{source}: #{message}"
  end # def to_s

  def [](key)
    return @data[key]
  end # def []

  def []=(key, value)
    @data[key] = value
  end # def []=

  def timestamp
    @data["timestamp"]
  end # def timestamp

  def source
    @data["source"]
  end # def source

  def message
    @data["message"]
  end # def message

  def to_hash
    return @data
  end # def to_hash

  def include?(key)
    return @data.include?(key)
  end
end; end # class LogStash::Event
