# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# The split filter is for splitting multiline messages into separate events.
#
# An example use case of this filter is for taking output from the 'exec' input
# which emits one event for the whole output of a command and splitting that
# output by newline - making each line an event.
#
# The end result of each split is a complete copy of the event 
# with only the current split section of the given field changed.
class LogStash::Filters::Punct < LogStash::Filters::Base

  config_name "punct"
  milestone 1

  # The field which value is split by the terminator
  config :field, :validate => :string, :default => "message"

  public
  def register
    # Nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    # events = []

    original_value = event[@field]

    # If for some reason the field is an array of values, take the first only.
    original_value = original_value.first if original_value.is_a?(Array)
    punct = original_value.tr('A-Za-z0-9 \t','')
    event["punct"] = punct
    # event.cancel
  end # def filter
end # class LogStash::Filters::Split
