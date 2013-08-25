require "logstash/filters/base"
require "logstash/namespace"

# JSON encode filter. Takes a field and serializes it into JSON
class LogStash::Filters::JsonEncode < LogStash::Filters::Base

  config_name "json_encode"
  milestone 2

  # Config for json_encode is:
  # 
  # * source => dest
  #
  # For example, if you have a field named 'foo', and you want to store the
  # JSON encoded string in 'bar', do this:
  #
  #     filter {
  #       json_encode {
  #         foo => bar
  #       }
  #     }
  #
  # Note: if the "dest" field already exists, it will be overridden.
  config /[A-Za-z0-9_@-]+/, :validate => :string

  public
  def register
    @json = {}

    @config.each do |field, dest|
      next if RESERVED.member?(field)

      @json[field] = dest
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running JSON encoder", :event => event)

    @json.each do |key, dest|
      next unless event[key]

      begin
        event[dest] = JSON.pretty_generate(event[key])
        filter_matched(event)
      rescue => e
        event.tag "_jsongeneratefailure"
        @logger.warn("Trouble encoding JSON", :key => key, :raw => event[key],
                      :exception => e)
        next
      end
    end

    @logger.debug("Event after JSON encoder", :event => event)
  end # def filter
end # class LogStash::Filters::JsonEncode
