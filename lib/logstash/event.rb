# encoding: utf-8
require "json"
require "time"
require "date"
require "logstash/namespace"
require "logstash/util/fieldreference"
require "logstash/util/accessors"
require "logstash/time_addon"

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

  CHAR_PLUS = "+"
  TIMESTAMP = "@timestamp"
  VERSION = "@version"
  VERSION_ONE = "1"

  public
  def initialize(data={})
    @logger = Cabin::Channel.get(LogStash)
    @cancelled = false

    @data = data
    @accessors = LogStash::Util::Accessors.new(data)

    data[VERSION] = VERSION_ONE if !@data.include?(VERSION)
    if data.include?(TIMESTAMP)
      t = data[TIMESTAMP]
      if t.is_a?(String)
        data[TIMESTAMP] = LogStash::Time.parse_iso8601(t)
      end
    else
      data[TIMESTAMP] = ::Time.now.utc
    end

    # Used to store proc callbacks given to the event class
    # event.on("some_event", &my_proc)
    @change_listeners = {}

    @default_change_listeners = {
      # When an event has gone through all filters and are pretty much ready to be sent
      "filter_processed" => [Proc.new {
        trigger("output_send")
      }],

      # After an input has seen enough filter_processed events for a batch of messages to be 'ready'
      "output_send" => [Proc.new {
        trigger("output_sent")
      }],

      # After an output has confirmed the message has been sent to an HA store
      "output_sent" => [Proc.new {
        trigger("input_acknowledged")
      }],

      # After an input has acked back to a batch of messages
      "input_acknowledged" => [Proc.new {
        #@logger.debug "acked message"
      }],
    }
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
      return self.sprintf("#{self["@timestamp"].iso8601} %{host} %{message}")
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
  def [](str)
    if str[0,1] == CHAR_PLUS
      # nothing?
    else
      # return LogStash::Util::FieldReference.exec(str, @data)
      @accessors.get(str)
    end
  end # def []

  public
  # keep []= implementation in sync with spec/test_utils.rb monkey patch
  # which redefines []= but using @accessors.strict_set
  def []=(str, value)
    if str == TIMESTAMP && !value.is_a?(Time)
      raise TypeError, "The field '@timestamp' must be a Time, not a #{value.class} (#{value})"
    end
    @accessors.set(str, value)
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
    # pickup new event @data and also pickup @accessors
    # otherwise it will be pointing on previous data
    @data = event.instance_variable_get(:@data)
    @accessors = event.instance_variable_get(:@accessors)

    #convert timestamp if it is a String
    if @data[TIMESTAMP].is_a?(String)
      @data[TIMESTAMP] = LogStash::Time.parse_iso8601(@data[TIMESTAMP])
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
  def remove(str)
    # return LogStash::Util::FieldReference.exec(str, @data) do |obj, key|
    #   next obj.delete(key)
    # end
    @accessors.del(str)
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

  def tag(value)
    # Generalize this method for more usability
    self["tags"] ||= []
    self["tags"] << value unless self["tags"].include?(value)
  end

  # State change notifications
  def trigger(state_change)
    callbacks = (
      @change_listeners[state_change] or
      @default_change_listeners[state_change]
    )

    callbacks.each do |callback|
      callback.call(self)
    end
  end

  def on(state_change, &callback)
    # Initialize state_change if it's not set already
    @change_listeners[state_change] ||= []
    @change_listeners[state_change].push(callback)
  end
end # class LogStash::Event

class LogStash::EventBundle
  def initialize
    @logger = Cabin::Channel.get(LogStash)
    @events = []
    @ready = false
  end

  def ready(ack_sequence)
    ack_sequence.call
    @ready = true
  end

  def add(event)
    throw "Cannot add event to ready bundle" if @ready
    @events.push(event)
  end

  def bail()
    # Unless it's an HA output, we've already acked
    # so do nothing here :)
  end

  class HA < LogStash::EventBundle
    def initialize
      super()
      @processed_count = 0
      @sent_count = 0
      @semaphore = Mutex.new
      @bailing = false
    end

    def ready(ack_sequence)
      @ack_sequence = ack_sequence

      all_processed = @semaphore.synchronize do
        @ready = true
        not @bailing and @processed_count == @events.size
      end

      broadcast "output_send" if all_processed
    end

    def bail()
      @semaphore.synchronize do
        @events.each do |e| e.cancel end
        @bailing = true
      end
    end

    def setup_callbacks(event)
      event.on('filter_processed') do
        all_processed = @semaphore.synchronize do
          @processed_count += 1
          not @bailing and @ready and @processed_count == @events.size
        end

        broadcast "output_send" if all_processed
      end

      event.on("output_sent") do
        if not @ready
          # Would be triggered in race condition
          #   Make sure you added the event object to the bundle _before_ allowing it to be processed
          #   Default actions inside the event may have triggered output_send sooner than add()
          throw "Triggered output_send on bundled event when bundle is not ready"
        end

        ack_ready = @semaphore.synchronize do
          @sent_count += 1
          not @bailing and @sent_count == @events.size
        end

        if ack_ready
          begin
            # Try to ack sequence, but if this fails there's nothing we can do anyway
            @ack_sequence.call
            broadcast "input_acknowledged"
          rescue
            @logger.info "Failed to ack sequence, perhaps the connection is closing?"
          end
        end
      end
    end

    def add(event)
      setup_callbacks(event)
      super(event) # add event to @events, et al
    end

    private
    def broadcast(state)
      @events.each do |e|
        e.trigger state
      end
    end
  end
end
