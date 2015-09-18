# encoding: utf-8
require "logstash/namespace"
require "logstash/event"
require "logstash/plugin"
require "logstash/logging"
require "logstash/config/mixin"
require "logstash/codecs/base"
require "logstash/util/decorators"

# This is the base class for Logstash inputs.
class LogStash::Inputs::Base < LogStash::Plugin
  include LogStash::Config::Mixin
  config_name "input"

  # Add a `type` field to all events handled by this input.
  #
  # Types are used mainly for filter activation.
  #
  # The type is stored as part of the event itself, so you can
  # also use the type to search for it in Kibana.
  #
  # If you try to set a type on an event that already has one (for
  # example when you send an event from a shipper to an indexer) then
  # a new input will not override the existing type. A type set at
  # the shipper stays with that event for its life even
  # when sent to another Logstash server.
  config :type, :validate => :string

  config :debug, :validate => :boolean, :default => false, :deprecated => "This setting no longer has any effect. In past releases, it existed, but almost no plugin made use of it."

  # The format of input data (plain, json, json_event)
  config :format, :validate => ["plain", "json", "json_event", "msgpack_event"], :deprecated => "You should use the newer 'codec' setting instead."

  # The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.
  config :codec, :validate => :codec, :default => "plain"

  # The character encoding used in this input. Examples include `UTF-8`
  # and `cp1252`
  #
  # This setting is useful if your log files are in `Latin-1` (aka `cp1252`)
  # or in another character set other than `UTF-8`.
  #
  # This only affects `plain` format logs since json is `UTF-8` already.
  config :charset, :deprecated => "Use the codec setting instead. For example: input { %PLUGIN% { codec => plain { charset => \"UTF-8\" } }"

  # If format is `json`, an event `sprintf` string to build what
  # the display `@message` should be given (defaults to the raw JSON).
  # `sprintf` format strings look like `%{fieldname}`
  #
  # If format is `json_event`, ALL fields except for `@type`
  # are expected to be present. Not receiving all fields
  # will cause unexpected results.
  config :message_format, :validate => :string, :deprecated => true

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
    @stop_called = Concurrent::AtomicBoolean.new(false)
    config_init(params)
    @tags ||= []

    if @charset && @codec.class.get_config.include?("charset")
      # charset is deprecated on inputs, but provide backwards compatibility
      # by copying the charset setting into the codec.

      @logger.info("Copying input's charset setting into codec", :input => self, :codec => @codec)
      charset = @charset
      @codec.instance_eval { @charset = charset }
    end

    # Backwards compat for the 'format' setting
    case @format
      when "plain"; # do nothing
      when "json"
        @codec = LogStash::Plugin.lookup("codec", "json").new
      when "json_event"
        @codec = LogStash::Plugin.lookup("codec", "oldlogstashjson").new
    end

  end # def initialize

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def tag(newtag)
    @tags << newtag
  end # def tag

  public
  # override stop if you need to do more than do_stop to
  # enforce the input plugin to return from `run`.
  # e.g. a tcp plugin might need to close the tcp socket
  # so blocking read operation aborts
  def stop
    # override if necessary
  end

  public
  def do_stop
    @logger.debug("stopping", :plugin => self)
    @stop_called.make_true
    stop
  end

  # stop? should never be overriden
  public
  def stop?
    @stop_called.value
  end

  protected
  def to_event(raw, source)
    raise LogStash::ThisMethodWasRemoved("LogStash::Inputs::Base#to_event - you should use codecs now instead of to_event. Not sure what this means? Get help on https://discuss.elastic.co/c/logstash")
  end # def to_event

  protected
  def decorate(event)
    # Only set 'type' if not already set. This is backwards-compatible behavior
    event["type"] = @type if @type && !event.include?("type")

    LogStash::Util::Decorators.add_fields(@add_field,event,"inputs/#{self.class.name}")
    LogStash::Util::Decorators.add_tags(@tags,event,"inputs/#{self.class.name}")
  end

  protected
  def fix_streaming_codecs
    require "logstash/codecs/plain"
    require "logstash/codecs/line"
    require "logstash/codecs/json"
    require "logstash/codecs/json_lines"
    case @codec
      when LogStash::Codecs::Plain
        @logger.info("Automatically switching from #{@codec.class.config_name} to line codec", :plugin => self.class.config_name)
        @codec = LogStash::Codecs::Line.new("charset" => @codec.charset)
      when LogStash::Codecs::JSON
        @logger.info("Automatically switching from #{@codec.class.config_name} to json_lines codec", :plugin => self.class.config_name)
        @codec = LogStash::Codecs::JSONLines.new("charset" => @codec.charset)
    end
  end
end # class LogStash::Inputs::Base
