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
  config :type, :validate => :string

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
  def filter(event, input_queue)
    raise "#{self.class}#filter must be overidden"
  end # def filter

  # a filter instance should call filter_matched from filter if the event
  # matches the filter's conditions (right type, etc)
  protected
  def filter_matched(event)
    (@add_field or {}).each do |field, value|
      event[field] ||= []
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
end # class LogStash::Filters::Base
