# encoding: utf-8
require "time"
require "date"
require "cabin"
require "logstash/namespace"
require "logstash/util/accessors"
require "logstash/timestamp"
require "logstash/json"
require "logstash/string_interpolation"

# transcient pipeline events for normal in-flow signaling as opposed to
# flow altering exceptions. for now having base classes is adequate and
# in the future it might be necessary to refactor using like a BaseEvent
# class to have a common interface for all pileline events to support
# eventual queueing persistence for example, TBD.
class LogStash::ShutdownEvent; end
class LogStash::FlushEvent; end

module LogStash
  FLUSH = LogStash::FlushEvent.new

  # LogStash::SHUTDOWN is used by plugins
  SHUTDOWN = LogStash::ShutdownEvent.new
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

  CHAR_PLUS = "+"
  TIMESTAMP = "@timestamp"
  VERSION = "@version"
  VERSION_ONE = "1"
  TIMESTAMP_FAILURE_TAG = "_timestampparsefailure"
  TIMESTAMP_FAILURE_FIELD = "_@timestamp"

  METADATA = "@metadata".freeze
  METADATA_BRACKETS = "[#{METADATA}]".freeze

  # Floats outside of these upper and lower bounds are forcibly converted
  # to scientific notation by Float#to_s
  MIN_FLOAT_BEFORE_SCI_NOT = 0.0001
  MAX_FLOAT_BEFORE_SCI_NOT = 1000000000000000.0

  DEFAULT_LOGGER = Cabin::Channel.get(LogStash)
  @@logger = DEFAULT_LOGGER

  def initialize(data = {})
    @cancelled = false
    @data = data
    @accessors = LogStash::Util::Accessors.new(data)
    @data[VERSION] ||= VERSION_ONE
    ts = @data[TIMESTAMP]
    @data[TIMESTAMP] = ts ? init_timestamp(ts) : LogStash::Timestamp.now

    @metadata = @data.delete(METADATA) || {}
    @metadata_accessors = LogStash::Util::Accessors.new(@metadata)
  end

  def cancel
    @cancelled = true
  end

  def uncancel
    @cancelled = false
  end

  def cancelled?
    @cancelled
  end

  # Create a deep-ish copy of this event.
  def clone
    copy = {}
    @data.each do |k,v|
      # TODO(sissel): Recurse if this is a hash/array?
      copy[k] = begin v.clone rescue v end
    end

    self.class.new(copy)
  end

  def to_s
    "#{timestamp.to_iso8601} #{self.sprintf("%{host} %{message}")}"
  end

  def timestamp
    @data[TIMESTAMP]
  end

  def timestamp=(val)
    @data[TIMESTAMP] = val
  end

  def [](fieldref)
    if fieldref.start_with?(METADATA_BRACKETS)
      @metadata_accessors.get(fieldref[METADATA_BRACKETS.length .. -1])
    elsif fieldref == METADATA
      @metadata
    else
      @accessors.get(fieldref)
    end
  end

  def []=(fieldref, value)
    if fieldref == TIMESTAMP && !value.is_a?(LogStash::Timestamp)
      raise TypeError, "The field '@timestamp' must be a (LogStash::Timestamp, not a #{value.class} (#{value})"
    end
    if fieldref.start_with?(METADATA_BRACKETS)
      @metadata_accessors.set(fieldref[METADATA_BRACKETS.length .. -1], value)
    elsif fieldref == METADATA
      @metadata = value
      @metadata_accessors = LogStash::Util::Accessors.new(@metadata)
    else
      @accessors.set(fieldref, value)
    end
  end

  def to_json(*args)
    # ignore arguments to respect accepted to_json method signature
    LogStash::Json.dump(@data)
  end

  def to_hash
    @data
  end

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

  def include?(fieldref)
    if fieldref.start_with?(METADATA_BRACKETS)
      @metadata_accessors.include?(fieldref[METADATA_BRACKETS.length .. -1])
    elsif fieldref == METADATA
      true
    else
      @accessors.include?(fieldref)
    end
  end

  # Append an event to this one.
  def append(event)
    # non-destructively merge that event with ourselves.

    # no need to reset @accessors here because merging will not disrupt any existing field paths
    # and if new ones are created they will be picked up.
    LogStash::Util.hash_merge(@data, event.to_hash)
  end

  # Remove a field or field reference. Returns the value of that field when deleted
  def remove(fieldref)
    @accessors.del(fieldref)
  end

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
  def sprintf(format)
    LogStash::StringInterpolation.evaluate(self, format)
  end

  def tag(value)
    # Generalize this method for more usability
    self["tags"] ||= []
    self["tags"] << value unless self["tags"].include?(value)
  end

  def to_hash_with_metadata
    @metadata.empty? ? to_hash : to_hash.merge(METADATA => @metadata)
  end

  def to_json_with_metadata(*args)
    # ignore arguments to respect accepted to_json method signature
    LogStash::Json.dump(to_hash_with_metadata)
  end

  # this is used by logstash-devutils spec_helper.rb to monkey patch the Event field setter []=
  # and add systematic encoding validation on every field set in specs.
  # TODO: (colin) this should be moved, probably in logstash-devutils ?
  def self.validate_value(value)
    case value
    when String
      raise("expected UTF-8 encoding for value=#{value}, encoding=#{value.encoding.inspect}") unless value.encoding == Encoding::UTF_8
      raise("invalid UTF-8 encoding for value=#{value}, encoding=#{value.encoding.inspect}") unless value.valid_encoding?
      value
    when Array
      value.each{|v| validate_value(v)} # don't map, return original object
      value
    else
      value
    end
  end

  # depracated public methods
  # TODO: (colin) since these depracated mothods are still exposed in 2.x we should remove them in 3.0

  def unix_timestamp
    raise DeprecatedMethod
  end

  def ruby_timestamp
    raise DeprecatedMethod
  end

  def fields
    raise DeprecatedMethod
  end

  # set a new logger for all Event instances
  # there is no point in changing it at runtime for other reasons than in tests/specs.
  # @param logger [Cabin::Channel] logger instance that will be used by all Event instances
  def self.logger=(logger)
    @@logger = logger
  end

  private

  def logger
    @@logger
  end

  def init_timestamp(o)
    begin
      timestamp = LogStash::Timestamp.coerce(o)
      return timestamp if timestamp

      logger.warn("Unrecognized #{TIMESTAMP} value, setting current time to #{TIMESTAMP}, original in #{TIMESTAMP_FAILURE_FIELD}field", :value => o.inspect)
    rescue LogStash::TimestampParserError => e
      logger.warn("Error parsing #{TIMESTAMP} string, setting current time to #{TIMESTAMP}, original in #{TIMESTAMP_FAILURE_FIELD} field", :value => o.inspect, :exception => e.message)
    end

    @data["tags"] ||= []
    @data["tags"] << TIMESTAMP_FAILURE_TAG unless @data["tags"].include?(TIMESTAMP_FAILURE_TAG)
    @data[TIMESTAMP_FAILURE_FIELD] = o

    LogStash::Timestamp.now
  end
end
