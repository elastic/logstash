# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# The punct filter is for strip all strings but punctutions.
#

class LogStash::Filters::Punct < LogStash::Filters::Base

  config_name "punct"
  milestone 1

  # The field which value is strip to punctution.
  config :field, :validate => :string, :default => "message"

  public
  def register
    # Nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    original_value = event[@field]

    # If for some reason the field is an array of values, take the first only.
    original_value = original_value.first if original_value.is_a?(Array)
    punct = original_value.tr('A-Za-z0-9 \t','')
    event["punct"] = punct
  end # def filter
end # class LogStash::Filters::Punct
