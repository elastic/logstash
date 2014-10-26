# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Drop filter.
#
# Drops everything that gets to this filter.
#
# This is best used in combination with conditionals, for example:
#
#     filter {
#       if [loglevel] == "debug" { 
#         drop { } 
#       }
#     }
#
# The above will only pass events to the drop filter if the loglevel field is
# "debug". This will cause all events matching to be dropped.
class LogStash::Filters::Drop < LogStash::Filters::Base
  config_name "drop"
  milestone 3
  # Drop all the events within a pre-configured percentage.
  #
  # This is useful if you just need a sample but not the whole.
  #
  # Example, to only drop around 40% of the events that have the field loglevel wiht value "debug".
  #
  #     filter {
  #       if [loglevel] == "debug" { 
  #         drop { 
  #           sample => 40
  #         } 
  #       }
  #     }
  config :sample, :validate => :number, :default => 100

  public
  def register
    # nothing to do.
  end

  public
  def filter(event)
    event.cancel if rand < (@sample / 100.0)
  end # def filter
end # class LogStash::Filters::Drop
