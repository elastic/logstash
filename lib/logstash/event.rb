require "json"
require "logstash/time"
require "logstash/namespace"
require "uri"

# General event type. Will expand this in the future.
class LogStash::Event
  public
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

  public
  def self.from_json(json)
    return LogStash::Event.new(JSON.parse(json))
  end # def self.from_json

  public
  def cancel
    @cancelled = true
  end

  public
  def cancelled?
    return @cancelled
  end

  public
  def to_s
    return "#{timestamp} #{source}: #{message}"
  end # def to_s

  public
  def timestamp; @data["@timestamp"]; end # def timestamp
  def timestamp=(val); @data["@timestamp"] = val; end # def timestamp=

  public
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

  public
  def message; @data["@message"]; end # def message
  def message=(val); @data["@message"] = val; end # def message=

  public
  def type; @data["@type"]; end # def type
  def type=(val); @data["@type"] = val; end # def type=

  public
  def tags; @data["@tags"]; end # def tags
  def tags=(val); @data["@tags"] = val; end # def tags=

  # field-related access
  public
  def [](key)
    # If the key isn't in fields and it starts with an "@" sign, get it out of data instead of fields
    if ! @data["@fields"].has_key?(key) and key.slice(0,1) == "@"
      return @data[key]
    # Exists in @fields (returns value) or doesn't start with "@" (return null)
    else
      return @data["@fields"][key]
    end
  end # def []
  
  # TODO(sissel): the semantics of [] and []= are now different in that
  # []= only allows you to assign to only fields (not metadata), but
  # [] allows you to read fields and metadata.
  # We should fix this. Metadata is really a namespace issue, anyway.
  def []=(key, value); @data["@fields"][key] = value end # def []=
  def fields; return @data["@fields"] end # def fields
  
  public
  def to_json; return @data.to_json end # def to_json
  def to_hash; return @data end # def to_hash

  public
  def overwrite(event)
    @data = event.to_hash
  end

  public
  def include?(key); return @data.include?(key) end

  # Append an event to this one.
  public
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
  end # def append

  # sprintf. This could use a better method name.
  # The idea is to take an event and convert it to a string based on 
  # any format values, delimited by ${foo} where 'foo' is a field or
  # metadata member.
  #
  # For example, if the event has @type == "foo" and @source == "bar"
  # then this string:
  #   "type is ${@type} and source is #{@source}"
  # will return
  #   "type is foo and source is bar"
  #
  # If a ${name} value does not exist, then no substitution occurs.
  #
  # TODO(sissel): It is not clear what the value of a field that 
  # is an array (or hash?) should be. Join by comma? Something else?
  public
  def sprintf(format)
    result = format.gsub(/\$\{[@A-Za-z0-9_-]+\}/) do |match|
      name = match[2..-2] # trim '${' and '}'
      value = (self[name] or match)
    end
    #$stderr.puts "sprintf(#{format.inspect}) => #{result.inspect}"
    return result
  end # def sprintf
end # class LogStash::Event
