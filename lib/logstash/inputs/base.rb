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
  config :charset, :validate => ::Encoding.name_list, :deprecated => true

  # If format is "json", an event sprintf string to build what
  # the display @message should be given (defaults to the raw JSON).
  # sprintf format strings look like %{fieldname} or %{@metadata}.
  #
  # If format is "json_event", ALL fields except for @type
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
    config_init(params)
    @tags ||= []

    if @charset && @codec.class.get_config.include?("charset")
      # charset is deprecated on inputs, but provide backwards compatibility
      # by copying the charset setting into the codec.

      @logger.warn("Copying input's charset setting into codec", :input => self, :codec => @codec)
      charset = @charset
      @codec.instance_eval { @charset = charset }
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

  protected
  def to_event(raw, source) 
    raise LogStash::ThisMethodWasRemoved("LogStash::Inputs::Base#to_event - you should use codecs now instead of to_event. Not sure what this means? Get help on logstash-users@googlegroups.com!")
  end # def to_event
end # class LogStash::Inputs::Base
