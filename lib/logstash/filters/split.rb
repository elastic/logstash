require "logstash/filters/base"
require "logstash/namespace"
require "logstash/event"

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

  # If true, the array data will be passed forward as a single hash element with @field as the key.
  # If false, treat the entire array element as a new event for further processing.
  config :reuse_element, :validate => :boolean, :default => true

  public
  def register
    # Nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    splits = []

    original_value = event[@field]

    if original_value.is_a?(Array)
      splits = original_value
    else
      # Using -1 for 'limit' on String#split makes ruby not drop trailing empty
      # splits.
      splits = original_value.split(@terminator, -1)
    end

    # Skip filtering if splitting this event resulted in only one thing found
    return if splits.length <= 1

    splits.each do |value|
      next if value.empty?

      event_split = nil
      if @reuse_element
        event_split = event.clone
        @logger.debug("Split event", :value => value, :field => @field)
        event_split[@field] = value
      else
        event_split = LogStash::Event.new(value)
      end
      filter_matched(event_split)

      # Push this new event onto the stack at the LogStash::FilterWorker
      yield event_split
    end

    # Cancel this event, we'll use the newly generated ones above.
    event.cancel
  end # def filter
end # class LogStash::Filters::Split
