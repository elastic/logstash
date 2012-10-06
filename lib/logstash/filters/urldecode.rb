require "logstash/filters/base"
require "logstash/namespace"
require "uri"

# The urldecode filter is for decoding events that are urlencoded.
class LogStash::Filters::Urldecode < LogStash::Filters::Base
  config_name "urldecode"
  plugin_status "beta"

  # The field which value is urldecoded
  config :field, :validate => :string, :default => "@message"

  # Urldecode all fields
  config :all_fields, :validate => :boolean, :default => false

  public
  def register
    # Nothing to do
  end #def register

  public
  def filter(event)
    return unless filter?(event)

    # If all_fields is true then try to decode them all
    if @all_fields
      event.fields.each do |name, value|
        # deal with arrays
        if value.is_a?(Array)
          all_vs = []
          value.each do |v|
            all_vs << URI.unescape(v)
          end
          event.fields[name] = all_vs
        else 
          event.fields[name] = URI.unescape(value)
        end #end if array
      end
    # Else decode the specified field
    else
      decode_field = event[@field]
      # deal with arrays
      if decode_field.is_a?(Array)
        all_vs = []
        decode_field.each do |v|
          all_vs << URI.unescape(v)
        end
        event[@field] = all_vs
      else
        event[@field] = URI.unescape(decode_field)
      end #end if array
    end
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Urldecode
