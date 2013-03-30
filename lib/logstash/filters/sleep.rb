require "logstash/filters/base"
require "logstash/namespace"

# Sleep a given amount of time. This will cause logstash
# to stall for the given amount of time. This is useful
# for rate limiting, etc.
class LogStash::Filters::Sleep < LogStash::Filters::Base
  config_name "sleep"
  plugin_status "experimental"

  # The length of time to sleep, in seconds, for every event.
  #
  # This can be a number (eg, 0.5), or a string (eg, "%{foo}") 
  # The second form (string with a field value) is useful if
  # you have an attribute of your event that you want to use
  # to indicate the amount of time to sleep.
  #
  # Example:
  #
  #     filter {
  #       sleep {
  #         # Sleep 1 second for every event.
  #         duration => "1"
  #       }
  #     }
  config :duration, :validate => :string, :required => true

  public
  def register
    # nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    case @duration
      when Fixnum, Float; sleep(@duration)
      else; sleep(event.sprintf(@duration).to_f)
    end
    filter_matched(event)
  end # def filter
end
