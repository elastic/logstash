require "logstash/filters/base"
require "logstash/namespace"

# Sleep a given amount of time. This will cause logstash
# to stall for the given amount of time. This is useful
# for rate limiting, etc.
#
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
  #         time => "1"
  #       }
  #     }
  config :time, :validate => :string

  # Enable replay mode.
  #
  # Replay mode tries to sleep based on timestamps in each event.
  #
  # The amount of time to sleep is computed by subtracting the
  # previous event's timestamp from the current event's timestamp.
  # This helps you replay events in the same timeline as original.
  #
  # If you specify a `time` setting as well, this filter will
  # use the `time` value as a speed modifier. For example,
  # a `time` value of 2 will replay at double speed, while a
  # value of 0.25 will replay at 1/4th speed.
  #
  # For example:
  #
  #     filter {
  #       sleep {
  #         time => 2
  #         replay => true
  #       }
  #     }
  #
  # The above will sleep in such a way that it will perform
  # replay 2-times faster than the original time speed.
  config :replay, :validate => :boolean, :default => false

  public
  def register
    if @replay && @time.nil?
      # Default time multiplier is 1 when replay is set.
      @time = 1
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    case @time
      when Fixnum, Float; time = @time
      when nil; # nothing
      else; time = event.sprintf(@time).to_f
    end

    if @replay
      clock = event.ruby_timestamp.to_f
      if @last_clock
        delay = clock - @last_clock
        sleeptime = delay/time
        if sleeptime > 0
          @logger.debug? && @logger.debug("Sleeping", :delay => sleeptime)
          sleep(sleeptime)
        end
      end
      @last_clock = clock
    else
      sleep(time)
    end
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Sleep
