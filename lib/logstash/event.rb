require "json"
require "time"
require "date"
require "logstash/time_addon"
require "logstash/namespace"
require "uri"

# General event type. 
# Basically a light wrapper on top of a hash.
#
# TODO(sissel): properly handle lazy properties like parsed time formats, urls,
# etc, as necessary.
class LogStash::Event
  public
  def initialize(data=nil)
    @cancelled = false

    @data = {
      "@source" => "unknown",
      "@tags" => [],
      "@fields" => {},
    }
    @data.merge!(data) unless data.nil?
    @data["@timestamp"] ||= LogStash::Time.now
  end # def initialize

  if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
    @@date_parser = Java::org.joda.time.format.ISODateTimeFormat.dateTimeParser.withOffsetParsed
  else
    # TODO(sissel): LOGSTASH-217
    @@date_parser ||= nil
  end

  public
  def self.from_json(json)
    return LogStash::Event.new(JSON.parse(json))
  end # def self.from_json

  public
  def cancel
    @cancelled = true
  end # def cancel

  public
  def uncancel
    @cancelled = false
  end # def uncancel

  public
  def cancelled?
    return @cancelled
  end # def cancelled?

  # Create a deep-ish copy of this event.
  public
  def clone
    newdata = @data.clone
    newdata["@fields"] = {}
    fields.each do |k,v|
      newdata["@fields"][k] = v.clone
    end
    return LogStash::Event.new(newdata)
  end # def clone

  public
  def to_s
    return self.sprintf("%{@timestamp} %{@source}: %{@message}")
  end # def to_s

  public
  def timestamp; @data["@timestamp"]; end # def timestamp
  def timestamp=(val); @data["@timestamp"] = val; end # def timestamp=

  public
  def unix_timestamp
    if RUBY_ENGINE != "jruby"
      # This is really slow. See LOGSTASH-217
      # For some reason, ::Time.parse isn't present even after 'require "time"'
      # so use DateTime.parse
      return ::DateTime.parse(timestamp).to_time.to_f
    else
      time = @@date_parser.parseDateTime(timestamp)
      return time.getMillis.to_f / 1000
    end
  end

  def ruby_timestamp
    return ::DateTime.parse(timestamp).to_time
  end  
  
  
  public
  def source; @data["@source"]; end # def source
  def source=(val)
    uri = URI.parse(val) rescue nil
    val = uri if uri
    if val.is_a?(URI)
      @data["@source"] = val.to_s
      @data["@source_host"] = val.host if @data["@source_host"].nil?
      @data["@source_path"] = val.path
    else
      @data["@source"] = val
    end
  end # def source=

  public
  def source_host; @data["@source_host"]; end # def source_host
  def source_host=(val); @data["@source_host"] = val; end # def source_host=

  public
  def source_path; @data["@source_path"]; end # def source_path
  def source_path=(val); @data["@source_path"] = val; end # def source_path=

  public
  def message; @data["@message"]; end # def message
  def message=(val); @data["@message"] = val; end # def message=

  public
  def type; @data["@type"]; end # def type
  def type=(val); @data["@type"] = val; end # def type=

  public
  def tags; @data["@tags"]; end # def tags
  def tags=(val); @data["@tags"] = val; end # def tags=

  def id; @data["@id"]; end # def id
  def id=(val); @data["@id"] = val; end # def id=

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
  
  public
  def []=(key, value)
    if @data.has_key?(key)
      @data[key] = value
    else
      @data["@fields"][key] = value
    end
  end # def []=

  def fields; return @data["@fields"] end # def fields
  
  public
  def to_json(*args); return @data.to_json(*args) end # def to_json
  def to_hash; return @data end # def to_hash

  public
  def overwrite(event)
    @data = event.to_hash
  end

  public
  def include?(key)
    return (@data.include?(key) or @data["@fields"].include?(key))
  end # def include?

  # Append an event to this one.
  public
  def append(event)
    if event.message
      if self.message
        self.message += "\n" + event.message 
      else
        self.message = event.message
      end
    end
    self.tags |= event.tags

    # Append all fields
    event.fields.each do |name, value|
      if self.fields.include?(name)
        if !self.fields[name].is_a?(Array)
          self.fields[name] = [self.fields[name]]
        end
        if value.is_a?(Array)
          self.fields[name] |= value
        else
          self.fields[name] << value unless self.fields[name].include?(value)
        end
      else
        self.fields[name] = value
      end
    end # event.fields.each
  end # def append

  # Remove a field. Returns the value of that field when deleted
  public
  def remove(field)
    if @data.has_key?(field)
      return @data.delete(field)
    else
      return @data["@fields"].delete(field)
    end
  end # def remove

  # sprintf. This could use a better method name.
  # The idea is to take an event and convert it to a string based on 
  # any format values, delimited by %{foo} where 'foo' is a field or
  # metadata member.
  #
  # For example, if the event has @type == "foo" and @source == "bar"
  # then this string:
  #   "type is %{@type} and source is %{@source}"
  # will return
  #   "type is foo and source is bar"
  #
  # If a %{name} value is an array, then we will join by ','
  # If a %{name} value does not exist, then no substitution occurs.
  #
  # TODO(sissel): It is not clear what the value of a field that 
  # is an array (or hash?) should be. Join by comma? Something else?
  public
  def sprintf(format)
    if format.index("%").nil?
      return format
    end

    return format.gsub(/%\{[^}]+\}/) do |tok|
      # Take the inside of the %{ ... }
      key = tok[2 ... -1]

      if key == "+%s"
        # Got %{+%s}, support for unix epoch time
        if RUBY_ENGINE != "jruby"
          # This is really slow. See LOGSTASH-217
          Time.parse(self.timestamp).to_i
        else
          datetime = @@date_parser.parseDateTime(self.timestamp)
          (datetime.getMillis / 1000).to_i
        end
      elsif key[0,1] == "+"
        # We got a %{+TIMEFORMAT} so use joda to format it.
        if RUBY_ENGINE != "jruby"
          # This is really slow. See LOGSTASH-217
          datetime = Date.parse(self.timestamp)
          format = key[1 .. -1]
          datetime.strftime(format)
        else
          datetime = @@date_parser.parseDateTime(self.timestamp)
          format = key[1 .. -1]
          datetime.toString(format) # return requested time format
        end
      else
        # Use an event field.
        value = nil
        obj = self

        # If the top-level value exists, use that and don't try
        # to "look" into data structures.
        if self[key]
          value = self[key]
        else
          # "." is what ES uses to access structured data, so adopt that
          # idea here, too.  "foo.bar" will access key "bar" under hash "foo".
          key.split('.').each do |segment|
            if obj
              value = obj[segment] rescue nil
              obj = obj[segment] rescue nil
            else
              value = nil
              break
            end
          end # key.split.each
        end # if self[key]

        case value
        when nil
          tok # leave the %{foo} if this field does not exist in this event.
        when Array
          value.join(",") # Join by ',' if value is an array
        when Hash
          value.to_json # Convert hashes to json
        else
          value # otherwise return the value
        end
      end
    end
  end # def sprintf

  public
  def ==(other)
    #puts "#{self.class.name}#==(#{other.inspect})"
    if !other.is_a?(self.class)
      return false
    end

    return other.to_hash == self.to_hash
  end # def ==
end # class LogStash::Event
