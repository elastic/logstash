# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# The split filter is for splitting arrays into separate events.
#
# An example use case of this filter is for taking input
# such as {"events": [ {"id":"1"}, {"id":"2"} ] } 
# and yielding each event.
class LogStash::Filters::SplitArray < LogStash::Filters::Base

  config_name "split_array"
  milestone 1

  # The field which value is split by the terminator
  config :source, :validate => :string, :default => "message"
  config :target, :validate => :string, :default => "message"

  public
  def register
    # Nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)


    original_value = event[@source]

    # Skip filtering if field is not an array
    return unless original_value.is_a?(Array)

    original_value.each do |value|

      new_event = event.clone
      new_event[@target] = value
      filter_matched(new_event)

      #print new_event
	
      # Push this new event onto the stack at the LogStash::FilterWorker
      yield new_event
    end

    # Cancel this event, we'll use the newly generated ones above.
    event.cancel
  end # def filter
end # class LogStash::Filters::SplitArray
