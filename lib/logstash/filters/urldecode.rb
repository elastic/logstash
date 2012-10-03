require "logstash/filters/base"
require "logstash/namespace"
require "uri"

# The urldecode filter is for decoding events that are urlencoded.
class LogStash::Filters::Urldecode < LogStash::Filters::Base
  config_name "urldecode"
  plugin_status "beta"

  # The field which value is urldecoded
  config :field, :validate => :string, :default => "@message"

  public
  def register
    # Nothing to do
  end #def register

  public
  def filter(event)
    return unless filter?(event)
    decode_field = event[@field]
    event[@field] = URI.unescape(decode_field)
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Urldecode
