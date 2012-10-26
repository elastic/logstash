require "logstash/namespace"
require "logstash/event"
require "logstash/plugin"
require "logstash/logging"
require "logstash/config/mixin"

# This is the base class for logstash inputs.
class LogStash::Inputs::Base < LogStash::Plugin
  include LogStash::Config::Mixin
  config_name "input"

  # Label this input with a type.
  # Types are used mainly for filter activation.
  #
  #
  # If you create an input with type "foobar", then only filters
  # which also have type "foobar" will act on them.
  #
  # The type is also stored as part of the event itself, so you
  # can also use the type to search for in the web interface.
  config :type, :validate => :string, :required => true

  # Set this to true to enable debugging on an input.
  config :debug, :validate => :boolean, :default => false

  # The format of input data (plain, json, json_event)
  config :format, :validate => ["plain", "json", "json_event"]

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
  def initialize(params)
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
      event.message = raw
    when "json"
      begin
        fields = JSON.parse(raw)
        fields.each { |k, v| event[k] = v }
        if @message_format
          event.message = event.sprintf(@message_format)
        else
          event.message = raw
        end
      rescue => e
        ## TODO(sissel): Instead of dropping the event, should we treat it as
        ## plain text and try to do the best we can with it?
        @logger.warn("Trouble parsing json input, falling back to plain text", :input => raw,
                     :source => source, :exception => e,
                     :backtrace => e.backtrace)
        event.message = raw
      end
    when "json_event"
      begin
        event = LogStash::Event.from_json(raw)
        if @message_format
          event.message ||= event.sprintf(@message_format)
        end
      rescue => e
        ## TODO(sissel): Instead of dropping the event, should we treat it as
        ## plain text and try to do the best we can with it?
        @logger.warn("Trouble parsing json input, falling back to plain text",
                     :input => raw, :source => source, :exception => e,
                     :backtrace => e.backtrace)
        event.message = raw
      end

      if event.source == "unknown"
        event.source = source
      end
    else
      raise "unknown event format #{@format}, this should never happen"
    end

    event.type ||= @type

    @add_field.each do |field, value|
       event[field] ||= []
       event[field] = [event[field]] if !event[field].is_a?(Array)
       event[field] << event.sprintf(value)
    end

    logger.debug(["Received new event", {:source => source, :event => event}])
    return event
  end # def to_event
end # class LogStash::Inputs::Base
