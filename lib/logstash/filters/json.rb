require "logstash/filters/base"
require "logstash/namespace"

# JSON filter. Takes a field that contains JSON and expands it into
# an actual datastructure.
class LogStash::Filters::Json < LogStash::Filters::Base

  config_name "json"
  milestone 2

  # Config for json is:
  #
  #     source => source_field
  #
  # For example, if you have json data in the @message field:
  #
  #     filter {
  #       json {
  #         source => "message"
  #       }
  #     }
  #
  # The above would parse the xml from the @message field
  config :source, :validate => :string, :required => true

  # Define target for placing the data. If this setting is omitted,
  # the json data will be stored at the root of the event.
  #
  # For example if you want the data to be put in the 'doc' field:
  #
  #     filter {
  #       json {
  #         target => "doc"
  #       }
  #     }
  #
  # json in the value of the source field will be expanded into a
  # datastructure in the "target" field.
  #
  # Note: if the "target" field already exists, it will be overwritten.
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
