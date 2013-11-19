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
class LogStash::Filters::Split < LogStash::Filters::Base

  config_name "split"
  milestone 2

  # The string to split on. This is usually a line terminator, but can be any
  # string.
  config :terminator, :validate => :string, :default => "\n"

  # The field which value is split by the terminator
  config :field, :validate => :string, :default => "message"

  public
  def register
    # Nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    events = []

    original_value = event[@field]

    # If for some reason the field is an array of values, take the first only.
    original_value = original_value.first if original_value.is_a?(Array)

    # Using -1 for 'limit' on String#split makes ruby not drop trailing empty
    # splits.
    splits = original_value.split(@terminator, -1)

    # Skip filtering if splitting this event resulted in only one thing found.
    return if splits.length == 1
    #or splits[1].empty?

    splits.each do |value|
      next if value.empty?

      event_split = event.clone
      @logger.debug("Split event", :value => value, :field => @field)
      event_split[@field] = value
      filter_matched(event_split)

      # Push this new event onto the stack at the LogStash::FilterWorker
      yield event_split
    end

    # Cancel this event, we'll use the newly generated ones above.
    event.cancel
  end # def filter
end # class LogStash::Filters::Split
