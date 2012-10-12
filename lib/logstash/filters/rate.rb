# rate filter
#
# This filter calculates message rates using various methods.
# 

require "logstash/filters/base"
require "logstash/namespace"
require "time/unit"

# The rate filter is for marking events based on the rate of similiar events.
# Rate is defined in terms of some aggregated metric for which the filter offers a few options:
# * Exponential running average
# * Linear decay running average
class LogStash::Filters::Rate < LogStash::Filters::Base

  config_name "rate"
  plugin_status "experimental"

  config :interval, :validate => :string, :default => "1 minute"

  config :threshold, :validate => :number, :required => true
  
  # The stream identity is how the rate filter determines which stream an
  # event belongs. This is generally used for differentiating, say, events
  # coming from multiple files in the same file input, or multiple connections
  # coming from a tcp input.
  #
  # The default value here is usually what you want, but there are some cases
  # where you want to change it. One such example is if you are using a tcp
  # input with only one client connecting at any time. If that client
  # reconnects (due to error or client restart), then logstash will identify
  # the new connection as a new stream and break any rate goodness that
  # may have occurred between the old and new connection. To solve this use
  # case, you can use "%{@source_host}.%{@type}" instead.
  config :stream_identity , :validate => :string, :default => "%{@source}.%{@type}"
  
  public
  def initialize(config = {})
    super

    @threadsafe = false

    # This filter needs to keep state.
    @counters = Hash.new { |h,k| h[k] = Hash.new } 
  end # def initialize

  public
  def register
    @interval_seconds = Time::Unit.parse(@interval.tr(" ", "")).seconds
    @alpha = 2.0/(@interval_seconds + 1)
    @logger.debug("Registered rate plugin", :type => @type, :config => @config)
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    event_stream_id = event.sprintf(@stream_identity)
    event_time = Time.now
    if @counters.has_key? event_stream_id
      time_delta = event_time - @counters[event_stream_id][:timestamp]
      time_delta = 0.001 if time_delta == 0 # should never be zero, but just to make sure...
      @counters[event_stream_id][:timestamp] = event_time
      @counters[event_stream_id][:value] = @alpha/time_delta + (1-@alpha) * @counters[event_stream_id][:value]
    else
      @counters[event_stream_id] = {:timestamp => event_time, :value => 0}
    end
    filter_matched(event) if @counters[event_stream_id][:value] * @interval_seconds > threshold
  end # def filter

end # class LogStash::Filters::Date
