# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"
require "logstash/plugin"
require "logstash/config/mixin"

class LogStash::Filters::Base < LogStash::Plugin
  include LogStash::Config::Mixin

  config_name "filter"

  # Note that all of the specified routing options (type,tags.exclude\_tags,include\_fields,exclude\_fields)
  # must be met in order for the event to be handled by the filter.

  # The type to act on. If a type is given, then this filter will only
  # act on messages with the same type. See any input plugin's "type"
  # attribute for more.
  # Optional.
  config :type, :validate => :string, :default => "", :deprecated => "You can achieve this same behavior with the new conditionals, like: `if [type] == \"sometype\" { %PLUGIN% { ... } }`."

  # Only handle events with all/any (controlled by include\_any config option) of these tags.
  # Optional.
  config :tags, :validate => :array, :default => [], :deprecated => "You can achieve similar behavior with the new conditionals, like: `if \"sometag\" in [tags] { %PLUGIN% { ... } }`"

  # Only handle events without all/any (controlled by exclude\_any config
  # option) of these tags.
  # Optional.
  config :exclude_tags, :validate => :array, :default => [], :deprecated => "You can achieve similar behavior with the new conditionals, like: `if !(\"sometag\" in [tags]) { %PLUGIN% { ... } }`"

  # If this filter is successful, add arbitrary tags to the event.
  # Tags can be dynamic and include parts of the event using the %{field}
  # syntax. Example:
  #
  #     filter {
  #       %PLUGIN% {
  #         add_tag => [ "foo_%{somefield}" ]
  #       }
  #     }
  #
  #     # You can also add multiple tags at once:
  #     filter {
  #       %PLUGIN% {
  #         add_tag => [ "foo_%{somefield}", "taggedy_tag"]
  #       }
  #     }
  #
  # If the event has field "somefield" == "hello" this filter, on success,
  # would add a tag "foo_hello" (and the second example would of course add a "taggedy_tag" tag).
  config :add_tag, :validate => :array, :default => []

  # If this filter is successful, remove arbitrary tags from the event.
  # Tags can be dynamic and include parts of the event using the %{field}
  # syntax. Example:
  #
  #     filter {
  #       %PLUGIN% {
  #         remove_tag => [ "foo_%{somefield}" ]
  #       }
  #     }
  #
  #     # You can also remove multiple tags at once:
  # 
  #     filter {
  #       %PLUGIN% {
  #         remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
  #       }
  #     }
  #
  # If the event has field "somefield" == "hello" this filter, on success,
  # would remove the tag "foo_hello" if it is present. The second example
  # would remove a sad, unwanted tag as well. 
  config :remove_tag, :validate => :array, :default => []

  # If this filter is successful, add any arbitrary fields to this event.
  # Field names can be dynamic and include parts of the event using the %{field}
  # Example:
  #
  #     filter {
  #       %PLUGIN% {
  #         add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
  #       }
  #     }
  #
  #     # You can also add multiple fields at once:
  #
  #     filter {
  #       %PLUGIN% {
  #         add_field => { 
  #           "foo_%{somefield}" => "Hello world, from %{host}"
  #           "new_field" => "new_static_value"
  #         }
  #       }
  #     }
  #
  # If the event has field "somefield" == "hello" this filter, on success,
  # would add field "foo_hello" if it is present, with the
  # value above and the %{host} piece replaced with that value from the
  # event. The second example would also add a hardcoded field. 
  config :add_field, :validate => :hash, :default => {}

  # If this filter is successful, remove arbitrary fields from this event.
  # Fields names can be dynamic and include parts of the event using the %{field}
  # Example:
  #
  #     filter {
  #       %PLUGIN% {
  #         remove_field => [ "foo_%{somefield}" ]
  #       }
  #     }
  #
  #     # You can also remove multiple fields at once:
  #
  #     filter {
  #       %PLUGIN% {
  #         remove_field => [ "foo_%{somefield}" "my_extraneous_field" ]
  #       }
  #     }
  #
  # If the event has field "somefield" == "hello" this filter, on success,
  # would remove the field with name "foo_hello" if it is present. The second 
  # example would remove an additional, non-dynamic field.
  config :remove_field, :validate => :array, :default => []

  RESERVED = ["type", "tags", "exclude_tags", "include_fields", "exclude_fields", "add_tag", "remove_tag", "add_field", "remove_field", "include_any", "exclude_any"]

  public
  def initialize(params)
    super
    config_init(params)
    @threadsafe = true
  end # def initialize

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def filter(event)
    raise "#{self.class}#filter must be overidden"
  end # def filter

  public
  def execute(event, &block)
    filter(event, &block)
  end # def execute

  public
  def threadsafe?
    @threadsafe
  end

  # a filter instance should call filter_matched from filter if the event
  # matches the filter's conditions (right type, etc)
  protected
  def filter_matched(event)
    @add_field.each do |field, value|
      field = event.sprintf(field)
      value = [value] if !value.is_a?(Array)
      value.each do |v|
        v = event.sprintf(v)
        if event.include?(field)
          event[field] = [event[field]] if !event[field].is_a?(Array)
          event[field] << v
        else
          event[field] = v
        end
        @logger.debug? and @logger.debug("filters/#{self.class.name}: adding value to field",
                                       :field => field, :value => value)
      end
    end
    
    @remove_field.each do |field|
      field = event.sprintf(field)
      @logger.debug? and @logger.debug("filters/#{self.class.name}: removing field",
                                       :field => field) 
      event.remove(field)
    end

    @add_tag.each do |tag|
      tag = event.sprintf(tag)
      @logger.debug? and @logger.debug("filters/#{self.class.name}: adding tag",
                                       :tag => tag)
      (event["tags"] ||= []) << tag
    end

    @remove_tag.each do |tag|
      break if event["tags"].nil?
      tag = event.sprintf(tag)
      @logger.debug? and @logger.debug("filters/#{self.class.name}: removing tag",
                                       :tag => tag)
      event["tags"].delete(tag)
    end
  end # def filter_matched

  protected
  def filter?(event)
    if !@type.empty?
      if event["type"] != @type
        @logger.debug? and @logger.debug(["filters/#{self.class.name}: Skipping event because type doesn't match #{@type}", event])
        return false
      end
    end

    if !@tags.empty?
      # this filter has only works on events with certain tags,
      # and this event has no tags.
      return false if !event["tags"]

      # Is @tags a subset of the event's tags? If not, skip it.
      if (event["tags"] & @tags).size != @tags.size
        @logger.debug(["filters/#{self.class.name}: Skipping event because tags don't match #{@tags.inspect}", event])
        return false
      end
    end

    if !@exclude_tags.empty? && event["tags"]
      if (diff_tags = (event["tags"] & @exclude_tags)).size != 0
        @logger.debug(["filters/#{self.class.name}: Skipping event because tags contains excluded tags: #{diff_tags.inspect}", event])
        return false
      end
    end

    return true
  end
end # class LogStash::Filters::Base
