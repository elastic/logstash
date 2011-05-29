require "logstash/namespace"
require "logstash/event"
require "logstash/plugin"
require "logstash/logging"
require "logstash/config/mixin"

class LogStash::Inputs::Base < LogStash::Plugin
  include LogStash::Config::Mixin
  attr_accessor :logger

  config_name "input"

  # Label this input with a type.
  config :type, :validate => :string, :required => true

  # Set this to true to enable debugging on an input.
  config :debug, :validate => :boolean, :default => false

  # The format of input data (plain, json, json_event)
  config :format, :validate => (lambda do |value|
    valid_formats = ["plain", "json", "json_event"]
    if value.length != 1
      false
    else
      valid_formats.member?(value.first)
    end
  end) # config :format

  # If format is "json", an event sprintf string to build what
  # the display @message should be (defaults to the raw JSON).
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

  public
  def initialize(params)
    @logger = LogStash::Logger.new(STDOUT)
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
  end
end # class LogStash::Inputs::Base
