# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "logstash/util/charset"
require "uri"

# The urldecode filter is for decoding fields that are urlencoded.
class LogStash::Filters::Urldecode < LogStash::Filters::Base
  config_name "urldecode"
  milestone 2

  # The field which value is urldecoded
  config :field, :validate => :string, :default => "message"

  # Urldecode all fields
  config :all_fields, :validate => :boolean, :default => false

  # Thel character encoding used in this filter. Examples include `UTF-8`
  # and `cp1252`
  #
  # This setting is useful if your url decoded string are in `Latin-1` (aka `cp1252`)
  # or in another character set other than `UTF-8`.
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  public
  def register
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = logger
  end #def register

  public
  def filter(event)
    return unless filter?(event)

    # If all_fields is true then try to decode them all
    if @all_fields
      event.to_hash.each { |name, value| event[name] = urldecode(value) }
    # Else decode the specified field
    else
      event[@field] = urldecode(event[@field])
    end
    filter_matched(event)
  end # def filter

  # Attempt to handle string, array, and hash values for fields.
  # For all other datatypes, just return, URI.unescape doesn't support them.
  private
  def urldecode(value)
    case value
    when String
      escaped = URI.unescape(value)
      return @converter.convert(escaped)
    when Array
      ret_values = []
      value.each { |v| ret_values << urldecode(v) }
      return ret_values
    when Hash
      ret_values = {}
      value.each { |k,v| ret_values[k] = urldecode(v) }
      return ret_values
    else
      return value
    end
  end
end # class LogStash::Filters::Urldecode