# encoding: utf-8
require "time"
require "date"
require "cabin"
require "logstash/namespace"
require "logstash/util/fieldreference"
require "logstash/util/accessors"
require "logstash/timestamp"
require "logstash/json"

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

  CHAR_PLUS = "+"
  TIMESTAMP = "@timestamp"
  VERSION = "@version"
  VERSION_ONE = "1"
  TIMESTAMP_FAILURE_TAG = "_timestampparsefailure"
  TIMESTAMP_FAILURE_FIELD = "_@timestamp"

  public
  def initialize(data = {})
    @logger = Cabin::Channel.get(LogStash)
    @cancelled = false
    @data = data
    @accessors = LogStash::Util::Accessors.new(data)
    @data[VERSION] ||= VERSION_ONE
    @data[TIMESTAMP] = init_timestamp(@data[TIMESTAMP])
  end # def initialize

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
      copy[k] = begin v.clone rescue v end
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
      return self.sprintf("#{timestamp.to_iso8601} %{host} %{message}")
    end # def to_s
  end

  public
  def timestamp; return @data[TIMESTAMP]; end # def timestamp
  def timestamp=(val); return @data[TIMESTAMP] = val; end # def timestamp=

  def unix_timestamp
    raise DeprecatedMethod
  end # def unix_timestamp

  def ruby_timestamp
    raise DeprecatedMethod
  end # def unix_timestamp

  # field-related access
  public
  def [](fieldref)
    @accessors.get(fieldref)
  end # def []

  public
  # keep []= implementation in sync with spec/test_utils.rb monkey patch
  # which redefines []= but using @accessors.strict_set
  def []=(fieldref, value)
    if fieldref == TIMESTAMP && !value.is_a?(LogStash::Timestamp)
      raise TypeError, "The field '@timestamp' must be a (LogStash::Timestamp, not a #{value.class} (#{value})"
    end
    @accessors.set(fieldref, value)
  end # def []=

  public
  def fields
    raise DeprecatedMethod
  end

  public
  def to_json
    LogStash::Json.dump(@data)
  end # def to_json

  public
  def to_hash
    @data
  end # def to_hash

  public
  def overwrite(event)
    # pickup new event @data and also pickup @accessors
    # otherwise it will be pointing on previous data
    @data = event.instance_variable_get(:@data)
    @accessors = event.instance_variable_get(:@accessors)

    #convert timestamp if it is a String
    if @data[TIMESTAMP].is_a?(String)
      @data[TIMESTAMP] = LogStash::Timestamp.parse_iso8601(@data[TIMESTAMP])
    end
  end

  public
  def include?(key)
    return !self[key].nil?
  end # def include?

  # Append an event to this one.
  public
  def append(event)
    # non-destructively merge that event with ourselves.

    # no need to reset @accessors here because merging will not disrupt any existing field paths
    # and if new ones are created they will be picked up.
    LogStash::Util.hash_merge(@data, event.to_hash)
  end # append

  # Remove a field or field reference. Returns the value of that field when
  # deleted
  public
  def remove(fieldref)
    @accessors.del(fieldref)
  end # def remove

  # sprintf. This could use a better method name.
  # The idea is to take an event and convert it to a string based on
  # any format values, delimited by %{foo} where 'foo' is a field or
  # metadata member.
  #
  # For example, if the event has type == "foo" and host == "bar"
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
        next @data[TIMESTAMP].to_i
      elsif key[0,1] == "+"
        t = @data[TIMESTAMP]
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
            LogStash::Json.dump(value) # Convert hashes to json
          else
            value # otherwise return the value
        end # case value
      end # 'key' checking
    end # format.gsub...
  end # def sprintf

  def tag(value)
    # Generalize this method for more usability
    self["tags"] ||= []
    self["tags"] << value unless self["tags"].include?(value)
  end

  private

  def init_timestamp(o)
    begin
      timestamp = o ? LogStash::Timestamp.coerce(o) : LogStash::Timestamp.now
      return timestamp if timestamp

      @logger.warn("Unrecognized #{TIMESTAMP} value, setting current time to #{TIMESTAMP}, original in #{TIMESTAMP_FAILURE_FIELD}field", :value => o.inspect)
    rescue LogStash::TimestampParserError => e
      @logger.warn("Error parsing #{TIMESTAMP} string, setting current time to #{TIMESTAMP}, original in #{TIMESTAMP_FAILURE_FIELD} field", :value => o.inspect, :exception => e.message)
    end

    @data["tags"] ||= []
    @data["tags"] << TIMESTAMP_FAILURE_TAG unless @data["tags"].include?(TIMESTAMP_FAILURE_TAG)
    @data[TIMESTAMP_FAILURE_FIELD] = o

    LogStash::Timestamp.now
  end
end # class LogStash::Event
