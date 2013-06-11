require "logstash/namespace"
require "logstash/event"
require "logstash/plugin"
require "logstash/logging"
require "logstash/config/mixin"
require "logstash/codecs/base"

# This is the base class for logstash inputs.
class LogStash::Inputs::Base < LogStash::Plugin
  include LogStash::Config::Mixin
  config_name "input"

  # Add a 'type' field to all events handled by this input.
  #
  # Types are used mainly for filter activation.
  #
  # If you create an input with type "foobar", then only filters
  # which also have type "foobar" will act on them.
  #
  # The type is also stored as part of the event itself, so you
  # can also use the type to search for in the web interface.
  #
  # If you try to set a type on an event that already has one (for
  # example when you send an event from a shipper to an indexer) then
  # a new input will not override the existing type. A type set at 
  # the shipper stays with that event for its life even
  # when sent to another LogStash server.
  config :type, :validate => :string

  # Set this to true to enable debugging on an input.
  config :debug, :validate => :boolean, :default => false

  # The format of input data (plain, json, json_event)
  config :format, :validate => ["plain", "json", "json_event", "msgpack_event"], :deprecated => true

  # The codec used for input data
  config :codec, :validate => :codec, :default => "plain"

  # The character encoding used in this input. Examples include "UTF-8"
  # and "cp1252"
  #
  # This setting is useful if your log files are in Latin-1 (aka cp1252)
  # or in another character set other than UTF-8.
  #
  # This only affects "plain" format logs since json is UTF-8 already.
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  # If format is "json", an event sprintf string to build what
  # the display @message should be given (defaults to the raw JSON).
  # sprintf format strings look like %{fieldname} or %{@metadata}.
  #
  # If format is "json_event", ALL fields except for @type
  # are expected to be present. Not receiving all fields
  # will cause unexpected results.
  config :message_format, :validate => :string

  # Add any number of arbitrary tags to your event.
  #
  # This can help with processing later.
  config :tags, :validate => :array

  # Add a field to an event
  config :add_field, :validate => :hash, :default => {}

  attr_accessor :params
  attr_accessor :threadable

  public
  def initialize(params={})
    super
    @threadable = false
    config_init(params)
    @tags ||= []
  end # def initialize

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def tag(newtag)
    @tags << newtag
  end # def tag

  protected
  def to_event(raw, source)
    @format ||= "plain"

    event = LogStash::Event.new
    event.tags = @tags.clone rescue []
    event.source = source

    case @format
    when "plain"
      raw.force_encoding(@charset)
      if @charset != "UTF-8"
        # Convert to UTF-8 if not in that character set.
        raw = raw.encode("UTF-8", :invalid => :replace, :undef => :replace)
      end
      event.message = raw
    when "json"
      begin
        # JSON must be valid UTF-8, and many inputs come from ruby IO
        # instances, which almost all default to ASCII-8BIT. Force UTF-8
        fields = JSON.parse(raw.force_encoding("UTF-8"))
        fields.each { |k, v| event[k] = v }
        if @message_format
          event.message = event.sprintf(@message_format)
        else
          event.message = raw
        end
      rescue => e
        # Instead of dropping the event, should we treat it as
        # plain text and try to do the best we can with it?
        @logger.info? and @logger.info("Trouble parsing json input, falling " \
                                       "back to plain text", :input => raw,
                                       :source => source, :exception => e)
        event.message = raw
        event.tags << "_jsonparsefailure"
      end
    when "json_event"
      begin
        # JSON must be valid UTF-8, and many inputs come from ruby IO
        # instances, which almost all default to ASCII-8BIT. Force UTF-8
        event = LogStash::Event.from_json(raw.force_encoding("UTF-8"))
        event["tags"] ||= []
        event["tags"] += @tags
        if @message_format
          event.message ||= event.sprintf(@message_format)
        end
      rescue => e
        # Instead of dropping the event, should we treat it as
        # plain text and try to do the best we can with it?
        @logger.info? and @logger.info("Trouble parsing json input, falling " \
                                       "back to plain text", :input => raw,
                                       :source => source, :exception => e, :stack => e.backtrace)
        event.message = raw
        event["tags"] ||= []
        event["tags"] << "_jsonparsefailure"
      end
    when "msgpack_event"
      begin
        # Msgpack does not care about UTF-8
        event = LogStash::Event.new(MessagePack.unpack(raw))
        event["tags"] ||= []
        event["tags"] |= @tags
        if @message_format
          event.message ||= event.sprintf(@message_format)
        end
      rescue => e
        ## TODO(sissel): Instead of dropping the event, should we treat it as
        ## plain text and try to do the best we can with it?
        @logger.warn("Trouble parsing msgpack input, falling back to plain text",
                     :input => raw, :source => source, :exception => e)
        event.message = raw
        event["tags"] ||= []
        event["tags"] << "_msgpackparsefailure"
      end

      if event.source == "unknown"
        event.source = source
      end
    else
      raise "unknown event format #{@format}, this should never happen"
    end

    event["type"] = @type if @type

    @add_field.each do |field, value|
      if event.include?(field)
        event[field] = [event[field]] if !event[field].is_a?(Array)
        event[field] << value
      else
        event[field] = value
      end
    end

    @logger.debug? and @logger.debug("Received new event", :source => source, :event => event)
    return event
  end # def to_event
end # class LogStash::Inputs::Base
