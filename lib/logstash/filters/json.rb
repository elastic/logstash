require "logstash/filters/base"
require "logstash/namespace"

# JSON filter. Takes a field that contains JSON and expands it into
# an actual datastructure.
class LogStash::Filters::Json < LogStash::Filters::Base

  config_name "json"
  plugin_status "beta"

  # Config for json is:
  #
  #     source => source_field
  #
  # For example, if you have json data in the @message field:
  #
  #     filter {
  #       json {
  #         source => "@message"
  #       }
  #     }
  #
  # The above would parse the xml from the @message field
  config :source, :validate => :string, :required => true

  # Define target for placing the data
  #
  # for example if you want the data to be put in the 'doc' field:
  #
  #     filter {
  #       json {
  #         target => "doc"
  #       }
  #     }
  #
  # json in the value of the source field will be expanded into a
  # datastructure in the "target" field.
  # Note: if the "target" field already exists, it will be overridden
  config :target, :validate => :string, :required => true

  public
  def register

    # Nothing to do here

  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running json filter", :event => event)

    matches = 0

    key = @source
    dest = @target

    return unless event[key]
    if event[key].is_a?(String)
      event[key] = [event[key]]
    end

    if event[key].length > 1
      @logger.warn("JSON filter only works on single fields (not lists)",
                   :key => key, :value => event[key])
      return
    end

    raw = event[key].first
    begin
      event[dest] = JSON.parse(raw)
      filter_matched(event)
    rescue => e
      event.tags << "_jsonparsefailure"
      @logger.warn("Trouble parsing json", :key => key, :raw => raw,
                    :exception => e)
      return
    end

    @logger.debug("Event after json filter", :event => event)

  end # def filter

end # class LogStash::Filters::Json
