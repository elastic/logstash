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

  public
  def register
    # Nothing to do here
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running json filter", :event => event)

    return unless event.include?(@source)

    if @target.nil?
      # Default is to write to the root of the event.
      dest = event.to_hash
    else
      dest = event[@target] ||= {}
    end

    begin
      # TODO(sissel): Note, this will not successfully handle json lists
      # like your text is '[ 1,2,3 ]' JSON.parse gives you an array (correctly)
      # which won't merge into a hash. If someone needs this, we can fix it
      # later.
      dest.merge!(JSON.parse(event[@source]))

      # This is a hack to help folks who are mucking with @timestamp during
      # their json filter. You aren't supposed to do anything with "@timestamp"
      # outside of the date filter, but nobody listens... ;)
      if event["@timestamp"].is_a?(String)
        event["@timestamp"] = Time.parse(event["@timestamp"]).gmtime
      end

      filter_matched(event)
    rescue => e
      event.tag("_jsonparsefailure")
      @logger.warn("Trouble parsing json", :source => @source,
                   :raw => event[@source], :exception => e)
      return
    end

    @logger.debug("Event after json filter", :event => event)

  end # def filter

end # class LogStash::Filters::Json
