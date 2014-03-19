# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# This is a JSON parsing filter. It takes an existing field which contains JSON and
# expands it into an actual data structure within the Logstash event.
#
# By default it will place the parsed JSON in the root (top level) of the Logstash event, but this
# filter can be configured to place the JSON into any arbitrary event field, using the
# `target` configuration.
class LogStash::Filters::Json < LogStash::Filters::Base

  config_name "json"
  milestone 2

  # The configuration for the JSON filter:
  #
  #     source => source_field
  #
  # For example, if you have JSON data in the @message field:
  #
  #     filter {
  #       json {
  #         source => "message"
  #       }
  #     }
  #
  # The above would parse the json from the @message field
  config :source, :validate => :string, :required => true

  # Define the target field for placing the parsed data. If this setting is
  # omitted, the JSON data will be stored at the root (top level) of the event.
  #
  # For example, if you want the data to be put in the 'doc' field:
  #
  #     filter {
  #       json {
  #         target => "doc"
  #       }
  #     }
  #
  # JSON in the value of the `source` field will be expanded into a
  # data structure in the `target` field.
  #
  # NOTE: if the `target` field already exists, it will be overwritten!
  config :target, :validate => :string

  TIMESTAMP = "@timestamp"

  public
  def register
    # Nothing to do here
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running json filter", :event => event)

    return unless event.include?(@source)

    source = event[@source]

    begin
      parsed = JSON.parse(source)
      if parsed.is_a?(Array)
        parsed.each do |e|
          new_event = event.clone
          dest = get_target(new_event)
          dest.merge!(e)
          parse_timestamp(new_event)
          filter_matched(new_event)
          yield new_event
        end
        event.cancel
      else
        dest = get_target(event)
        dest.merge!(parsed)
        parse_timestamp(event)
        filter_matched(event)
      end
    rescue => e
      event.tag("_jsonparsefailure")
      @logger.warn("Trouble parsing json", :source => @source,
                   :raw => event[@source], :exception => e)
      return
    end

    @logger.debug("Event after json filter", :event => event)

  end # def filter

  private
  def get_target(event)
    if @target.nil?
      # Default is to write to the root of the event.
      dest = event.to_hash
    else
      if @target == @source
        # Overwrite source
        dest = event[@target] = {}
      else
        dest = event[@target] ||= {}
      end
    end
    return dest
  end # def get_target

  def parse_timestamp(event)
      # If no target, we target the root of the event object. This can allow
      # you to overwrite @timestamp. If so, let's parse it as a timestamp!
      if !@target && event[TIMESTAMP].is_a?(String)
        # This is a hack to help folks who are mucking with @timestamp during
        # their json filter. You aren't supposed to do anything with
        # "@timestamp" outside of the date filter, but nobody listens... ;)
        event[TIMESTAMP] = Time.parse(event[TIMESTAMP]).utc
      end
  end # def parse_timestamp

end # class LogStash::Filters::Json
