require "logstash/namespace"
require "logstash/logging"
require "logstash/plugin"
require "logstash/config/mixin"

class LogStash::Filters::Base < LogStash::Plugin
  include LogStash::Config::Mixin

  config_name "filter"

  # The type to act on. If a type is given, then this filter will only
  # act on messages with the same type. See any input plugin's "type"
  # attribute for more.
  # Optional.
  config :type, :validate => :string, :default => ""

  # Only handle events with all of these tags.  Note that if you specify
  # a type, the event must also match that type.
  # Optional.
  config :tags, :validate => :array, :default => []

  # Only handle events without any of these tags. Note this check is additional to type and tags.
  config :exclude_tags, :validate => :array, :default => []

  # If this filter is successful, add arbitrary tags to the event.
  # Tags can be dynamic and include parts of the event using the %{field}
  # syntax. Example:
  #
  #     filter {
  #       myfilter {
  #         add_tag => [ "foo_%{somefield}" ]
  #       }
  #     }
  #
  # If the event has field "somefield" == "hello" this filter, on success,
  # would add a tag "foo_hello"
  config :add_tag, :validate => :array, :default => []

  # If this filter is successful, add any arbitrary fields to this event.
  # Example:
  #
  #     filter {
  #       myfilter {
  #         add_field => [ "sample", "Hello world, from %{@source}" ]
  #       }
  #     }
  #
  #  On success, myfilter will then add field 'sample' with the value above
  #  and the %{@source} piece replaced with that value from the event.
  config :add_field, :validate => :hash, :default => {}

  RESERVED = ["type", "tags", "add_tag", "add_field"]

  public
  def initialize(params)
    super
    config_init(params)
  end # def initialize

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def prepare_metrics
    @filter_metric = @logger.metrics.timer(self)
  end # def prepare_metrics

  public
  def filter(event)
    raise "#{self.class}#filter must be overidden"
  end # def filter

  public
  def execute(event, &block)
    @filter_metric.time do
      filter(event, &block)
    end
  end # def execute

  # a filter instance should call filter_matched from filter if the event
  # matches the filter's conditions (right type, etc)
  protected
  def filter_matched(event)
    (@add_field or {}).each do |field, value|
      event[field] ||= []
      event[field] = [event[field]] if !event[field].is_a?(Array)
      event[field] << event.sprintf(value)
      @logger.debug("filters/#{self.class.name}: adding value to field",
                    :field => field, :value => value)
    end

    (@add_tag or []).each do |tag|
      @logger.debug("filters/#{self.class.name}: adding tag", :tag => tag)
      event.tags << event.sprintf(tag)
      #event.tags |= [ event.sprintf(tag) ]
    end
  end # def filter_matched

  protected
  def filter?(event)
    if !@type.empty?
      if event.type != @type
        @logger.debug(["Dropping event because type doesn't match #{@type}", event])
        return false
      end
    end

    if !@tags.empty?
      if (event.tags & @tags).size != @tags.size
        @logger.debug(["Dropping event because tags don't match #{@tags.inspect}", event])
        return false
      end
    end

    if !@exclude_tags.empty?
      if (diff_tags = (event.tags & @exclude_tags)).size != 0
        @logger.debug(["Dropping event because tags contains excluded tags: #{diff_tags.inspect}", event])
        return false
      end
    end

    return true
  end
end # class LogStash::Filters::Base
