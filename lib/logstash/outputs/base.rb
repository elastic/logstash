require "cgi"
require "logstash/event"
require "logstash/logging"
require "logstash/plugin"
require "logstash/namespace"
require "logstash/config/mixin"
require "uri"

class LogStash::Outputs::Base < LogStash::Plugin
  include LogStash::Config::Mixin

  config_name "output"

  # The type to act on. If a type is given, then this output will only
  # act on messages with the same type. See any input plugin's "type"
  # attribute for more.
  # Optional.
  config :type, :validate => :string, :default => "", :deprecated => true

  # Only handle events with all of these tags.  Note that if you specify
  # a type, the event must also match that type.
  # Optional.
  config :tags, :validate => :array, :default => [], :deprecated => true

  # Only handle events without any of these tags. Note this check is additional to type and tags.
  config :exclude_tags, :validate => :array, :default => [], :deprecated => true

  # The codec used for output data
  config :codec, :validate => :codec, :default => "plain"

  public
  def initialize(params={})
    super
    config_init(params)
  end

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def receive(event)
    raise "#{self.class}#receive must be overidden"
  end # def receive

  public
  def handle(event)
    if event == LogStash::SHUTDOWN
      @codec.teardown if @codec.is_a? LogStash::Codecs::Base
      finished
      return
    end

    receive(event)
  end # def handle

  private
  def output?(event)
    if !@type.empty?
      if event.type != @type
        @logger.debug? and @logger.debug(["Dropping event because type doesn't match #{@type}", event])
        return false
      end
    end

    if !@tags.empty?
      if !@tags.send(@include_method) {|tag| event.tags.include?(tag)}
        @logger.debug? and @logger.debug(["Dropping event because tags don't match #{@tags.inspect}", event])
        return false
      end
    end

    if !@exclude_tags.empty?
      if @exclude_tags.send(@exclude_method) {|tag| event.tags.include?(tag)}
        @logger.debug? and @logger.debug(["Dropping event because tags contains excluded tags: #{exclude_tags.inspect}", event])
        return false
      end
    end

    return true
  end
end # class LogStash::Outputs::Base
