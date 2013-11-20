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

  public
  def register
    # nothing to do.
  end

  public
  def filter(event)
    event.cancel
  end # def filter
end # class LogStash::Filters::Drop
