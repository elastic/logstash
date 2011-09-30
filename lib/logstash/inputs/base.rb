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
  config :message_format, :validate => :string

  # Add any number of arbitrary tags to your event.
  #
  # This can help with processing later.
  config :tags, :validate => :array

  #config :tags, :validate => (lambda do |value|
    #re = /^[A-Za-z0-9_]+$/
    #value.each do |v|
      #if v !~ re
        #return [false, "Tag '#{v}' does not match #{re}"]
      #end # check 'v'
    #end # value.each
    #return true
  #end) # config :tag

  attr_accessor :params

  public
  def initialize(params)
    super
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
    @format ||= ["plain"]

    event = LogStash::Event.new
    event.type = @type
    event.tags = @tags.clone rescue []
    event.source = source

    case @format.first
    when "plain"
      event.message = raw
    when "json"
      begin
        fields = JSON.parse(raw)
        fields.each { |k, v| event[k] = v }
      rescue => e
        @logger.warn({:message => "Trouble parsing json input",
                      :input => raw,
                      :source => source,
                     })
        @logger.debug(["Backtrace", e.backtrace])
        return nil
      end

      if @message_format
        event.message = event.sprintf(@message_format)
      else
        event.message = raw
      end
    when "json_event"
      begin
        event = LogStash::Event.from_json(raw)
      rescue => e
        @logger.warn({:message => "Trouble parsing json_event input",
                      :input => raw,
                      :source => source,
                     })
        @logger.debug(["Backtrace", e.backtrace])
        return nil
      end
    else
      raise "unknown event format #{@format.first}, this should never happen"
    end

    logger.debug(["Received new event", {:source => source, :event => event}])
    return event
  end # def to_event
end # class LogStash::Inputs::Base
