# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Strip everything but punctuation from a field and store the remainder in the
# a separate field. This is often used for fingerprinting log events.
class LogStash::Filters::Punct < LogStash::Filters::Base
  config_name "punct"
  milestone 1

  # The field reference to use for punctuation stripping
  config :source, :validate => :string, :default => "message"

  # The field to store the result.
  config :target, :validate => :string, :default => "punct"

  public
  def register
    # Nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    original_value = event[@source]

    # If for some reason the field is an array of values, take the first only.
    original_value = original_value.first if original_value.is_a?(Array)
    event[@target] = original_value.tr('A-Za-z0-9 \t','')
  end # def filter
end # class LogStash::Filters::Punct
