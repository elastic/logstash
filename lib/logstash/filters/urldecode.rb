# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "uri"

# The urldecode filter is for decoding fields that are urlencoded.
class LogStash::Filters::Urldecode < LogStash::Filters::Base
  config_name "urldecode"
  milestone 2

  # The field which value is urldecoded
  config :field, :validate => :string, :default => "message"

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
      event.to_hash.each do |name, value|
        event[name] = urldecode(value)
      end
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
      return URI.unescape(value)
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
