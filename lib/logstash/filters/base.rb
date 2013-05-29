require "logstash/namespace"
require "logstash/logging"
require "logstash/plugin"
require "logstash/config/mixin"

class LogStash::Filters::Base < LogStash::Plugin
  include LogStash::Config::Mixin

  config_name "filter"

  # Note that all of the specified routing options (type,tags.exclude_tags,include_fields,exclude_fields)
  # must be met in order for the event to be handled by the filter.

  # The type to act on. If a type is given, then this filter will only
  # act on messages with the same type. See any input plugin's "type"
  # attribute for more.
  # Optional.
  config :type, :validate => :string, :default => ""

  # Only handle events with all/any (controlled by include_any config option) of these tags.
  # Optional.
  # TODO(piavlo): sould we rename/alias this to include_tags for clearness and consistency?
  config :tags, :validate => :array, :default => []

  # Only handle events without all/any (controlled by exclude_any config option) of these tags.
  # Optional.
  config :exclude_tags, :validate => :array, :default => []

  # Only handle events with all/any (controlled by include_any config option) of these fields.
  # Optional.
  config :include_fields, :validate => :array, :default => []

  # Only handle events without all/any (controlled by exclude_any config option) of these fields.
  # Optional.
  config :exclude_fields, :validate => :array, :default => []

  # Should all or any of the specified tags/include_fields be present for event to
  # be handled. Defaults to all.
  config :include_any, :validate => :boolean, :default => false

  # Should all or any of the specified exclude_tags/exclude_fields be missing for event to
  # be handled. Defaults to all.
  config :exclude_any, :validate => :boolean, :default => true

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
  # If the event has field "somefield" == "hello" this filter, on success,
  # would add a tag "foo_hello"
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
  # If the event has field "somefield" == "hello" this filter, on success,
  # would remove the tag "foo_hello" if it is present
  config :remove_tag, :validate => :array, :default => []

  # If this filter is successful, add any arbitrary fields to this event.
  # Tags can be dynamic and include parts of the event using the %{field}
  # Example:
  #
  #     filter {
  #       %PLUGIN% {
  #         add_field => [ "foo_%{somefield}", "Hello world, from %{@source}" ]
  #       }
  #     }
  #
  # If the event has field "somefield" == "hello" this filter, on success,
  # would add field "foo_hello" if it is present, with the
  # value above and the %{@source} piece replaced with that value from the
  # event.
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
  # If the event has field "somefield" == "hello" this filter, on success,
  # would remove the field with name "foo_hello" if it is present
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
      value = event.sprintf(value)
      if event.include?(field)
        event[field] = [event[field]] if !event[field].is_a?(Array)
        event[field] << value
      else
        event[field] = value
      end
      @logger.debug? and @logger.debug("filters/#{self.class.name}: adding value to field",
                                       :field => field, :value => value)
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
      event.tags << tag
    end

    @remove_tag.each do |tag|
      tag = event.sprintf(tag)
      @logger.debug? and @logger.debug("filters/#{self.class.name}: removing tag",
                                       :tag => tag)
      event.tags.delete(tag)
    end
  end # def filter_matched

  protected
  def filter?(event)
    if !@type.empty?
      if event.type != @type
        @logger.debug? and @logger.debug(["Skipping event because type doesn't match #{@type}", event])
        return false
      end
    end

    # TODO(piavlo): It would much nicer to set this in the "raising" register method somehow?
    include_method = @include_any ? :any? : :all?
    exclude_method = @exclude_any ? :any? : :all?

    if !@tags.empty?
      if !@tags.send(include_method) {|tag| event.tags.include?(tag)}
        @logger.debug? and @logger.debug(["Skipping event because tags don't match #{@tags.inspect}", event])
        return false
      end
    end

    if !@exclude_tags.empty?
      if @exclude_tags.send(exclude_method) {|tag| event.tags.include?(tag)}
        @logger.debug? and @logger.debug(["Skipping event because tags contains excluded tags: #{exclude_tags.inspect}", event])
        return false
      end
    end

    if !@include_fields.empty?
      if !@include_fields.send(include_method) {|field| event.include?(field)}
        @logger.debug? and @logger.debug(["Skipping event because fields don't match #{@include_fields.inspect}", event])
        return false
      end
    end

    if !@exclude_fields.empty?
      if @exclude_fields.send(exclude_method) {|field| event.include?(field)}
        @logger.debug? and @logger.debug(["Skipping event because fields contain excluded fields #{@exclude_fields.inspect}", event])
        return false
      end
    end

    return true
  end
end # class LogStash::Filters::Base
