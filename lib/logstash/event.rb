require "json"
require "time"
require "date"
require "logstash/namespace"
require "logstash/util/fieldreference"

# Use a custom serialization for jsonifying Time objects.
# TODO(sissel): Put this in a separate file.
class Time
  def to_json(*args)
    return iso8601(3).to_json(*args)
  end

  def inspect
    return to_json
  end
end

# the logstash event object.
#
# An event is simply a tuple of (timestamp, data).
# The 'timestamp' is an ISO8601 timestamp. Data is anything - any message,
# context, references, etc that are relevant to this event.
#
# Internally, this is represented as a hash with only two guaranteed fields.
#
# * "@timestamp" - an ISO8601 timestamp representing the time the event
#   occurred at.
# * "@version" - the version of the schema. Currently "1"
#
# They are prefixed with an "@" symbol to avoid clashing with your
# own custom fields. 
#
# When serialized, this is represented in JSON. For example:
#
#     {
#       "@timestamp": "2013-02-09T20:39:26.234Z",
#       "@version": "1",
#       message: "hello world"
#     }
class LogStash::Event
  class DeprecatedMethod < StandardError; end

  public
  def initialize(data={})
    @cancelled = false

    @data = data
    if data.include?("@timestamp")
      t = data["@timestamp"]
      if t.is_a?(String)
        data["@timestamp"] = Time.parse(t).gmtime
      end
    else
      data["@timestamp"] = ::Time.now.utc 
    end
    data["@version"] = "1" if !@data.include?("@version")
  end # def initialize

  # Add class methods on inclusion.
  public
  def self.included(klass)
    klass.extend(ClassMethods)
  end # def included

  module ClassMethods
    public
    def from_json(json)
      return self.new(JSON.parse(json))
    end # def from_json
  end

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
    copy = {}
    @data.each do |k,v|
      # TODO(sissel): Recurse if this is a hash/array?
      copy[k] = v.clone
    end
    return self.class.new(copy)
  end # def clone

  if RUBY_ENGINE == "jruby"
    public
    def to_s
      return self.sprintf("%{+yyyy-MM-dd'T'HH:mm:ss.SSSZ} %{host} %{message}")
    end # def to_s
  else
    public
    def to_s
      return self.sprintf("#{self["@timestamp"].iso8601} %{host} %{message}")
    end # def to_s
  end

  public
  def timestamp; return @data["@timestamp"]; end # def timestamp
  def timestamp=(val); return @data["@timestamp"] = val; end # def timestamp=

  def unix_timestamp
    raise DeprecatedMethod
  end # def unix_timestamp

  def ruby_timestamp
    raise DeprecatedMethod
  end # def unix_timestamp
  
  # field-related access
  public
  def [](str)
    if str[0,1] == "+"
    else
      return LogStash::Util::FieldReference.exec(str, @data)
    end
  end # def []
  
  public
  def []=(str, value)
    r = LogStash::Util::FieldReference.exec(str, @data) do |obj, key|
      obj[key] = value
    end

    # The assignment can fail if the given field reference (str) does not exist
    # In this case, we'll want to set the value manually.
    if r.nil?
      # TODO(sissel): Implement this in LogStash::Util::FieldReference
      if str[0,1] != "["
        return @data[str] = value
      end

      # No existing element was found, so let's set one.
      *parents, key = str.scan(/(?<=\[)[^\]]+(?=\])/)
      obj = @data
      parents.each do |p|
        if obj.include?(p)
          obj = obj[p]
        else
          obj[p] = {}
          obj = obj[p]
        end
      end
      obj[key] = value
    end
    return value
  end # def []=

  public
  def fields
    raise DeprecatedMethod
  end
  
  public
  def to_json(*args)
    return @data.to_json(*args) 
  end # def to_json

  def to_hash
    return @data
  end # def to_hash

  public
  def overwrite(event)
    @data = event.to_hash
  end

  public
  def include?(key)
    return !self[key].nil?
  end # def include?

  # Append an event to this one.
  public
  def append(event)
    # non-destructively merge that event with ourselves.
    LogStash::Util.hash_merge(@data, event.to_hash)
  end # append

  # Remove a field or field reference. Returns the value of that field when
  # deleted
  public
  def remove(str)
    return LogStash::Util::FieldReference.exec(str, @data) do |obj, key|
      next obj.delete(key)
    end
  end # def remove

  # sprintf. This could use a better method name.
  # The idea is to take an event and convert it to a string based on 
  # any format values, delimited by %{foo} where 'foo' is a field or
  # metadata member.
  #
  # For example, if the event has type == "foo" and source == "bar"
  # then this string:
  #   "type is %{type} and source is %{host}"
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
    format = format.to_s
    if format.index("%").nil?
      return format
    end

    return format.gsub(/%\{[^}]+\}/) do |tok|
      # Take the inside of the %{ ... }
      key = tok[2 ... -1]

      if key == "+%s"
        # Got %{+%s}, support for unix epoch time
        next @data["@timestamp"].to_i
      elsif key[0,1] == "+"
        t = @data["@timestamp"]
        formatter = org.joda.time.format.DateTimeFormat.forPattern(key[1 .. -1])\
          .withZone(org.joda.time.DateTimeZone::UTC)
        #next org.joda.time.Instant.new(t.tv_sec * 1000 + t.tv_usec / 1000).toDateTime.toString(formatter)
        # Invoke a specific Instant constructor to avoid this warning in JRuby
        #  > ambiguous Java methods found, using org.joda.time.Instant(long)
        org.joda.time.Instant.java_class.constructor(Java::long).new_instance(
          t.tv_sec * 1000 + t.tv_usec / 1000
        ).to_java.toDateTime.toString(formatter)
      else
        value = self[key]
        case value
          when nil
            tok # leave the %{foo} if this field does not exist in this event.
          when Array
            value.join(",") # Join by ',' if value is an array
          when Hash
            value.to_json # Convert hashes to json
          else
            value # otherwise return the value
        end # case value
      end # 'key' checking
    end # format.gsub...
  end # def sprintf

  # Shims to remove after event v1 is the default.
  def tags=(value); self["tags"] = value; end
  def tags; return self["tags"]; end
  def message=(value); self["message"] = value; end
  def source=(value); self["source"] = value; end
  def type=(value); self["type"] = value; end
  def type; return self["type"]; end
  def fields; return self.to_hash; end

  def tag(value)
    # Generalize this method for more usability
    self["tags"] ||= []
    self["tags"] << value unless self["tags"].include?(value)
  end
end # class LogStash::Event
