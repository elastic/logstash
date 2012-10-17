# rate filter
#
# This filter calculates message rates using various methods.
# 

require "logstash/filters/base"
require "logstash/namespace"
require "time/unit"

# The rate filter is for marking events based on the rate of similiar events.
# Rate is defined in terms of some aggregated metric for which the filter offers a few options (see below).
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
  # where you want to change it. For example, suppose you want to send alerts
  # if some IP connected too frequently to your server - you could set the 
  # stream_identity to something like "%{@type}.%{remote_address}"
  config :stream_identity , :validate => :string, :default => "%{@source}.%{@type}"

  # There are multiple methods of calculating/estimating rate. The rate filters supports the following:
  # * EWMA - Exponential weighted moving average: For every new matching event,
  #   calculate the current "rate" (1/ time since last event) then apply EWMA to it.
  #   See https://en.wikipedia.org/wiki/Moving_average#Exponential_moving_average
  # * COUNT: Keep a record of every matching event in a rolling time interval window then compute (count / time_interval)
  config :mode, :validate => ["EWMA", "COUNT"], :default => "EWMA"
  
  public
  def initialize(config = {})
    super

    @threadsafe = false

  end # def initialize

  public
  def register
    @interval_seconds = Time::Unit.parse(@interval.tr(" ", "")).seconds
    @logger.debug("Registered rate plugin", :type => @type, :config => @config)
    @rate_method = method("rate_#{mode}")
    @rate_threshold = threshold.to_f / @interval_seconds
    send("prepare_#{mode}")
  end # def register

  def filter(event)
    return unless filter?(event)
    filter_matched(event) if rate(event) > @rate_threshold
  end # def filter

  private

  def rate(event)
    event_stream_id = event.sprintf(stream_identity)
    event_time = event.unix_timestamp
    @rate_method.call(event, event_stream_id, event_time)
  end

  def prepare_EWMA
    @counters = Hash.new { |h,k| h[k] = Hash.new } 
  end

  def rate_EWMA(event, stream_id, event_time)
    if @counters.has_key? stream_id
      time_delta = event_time - @counters[stream_id][:timestamp]
      time_delta = 0.001 if time_delta == 0 # should never be zero, but just to make sure...
      @counters[stream_id][:timestamp] = event_time
      alpha = (1 - Math.exp(- time_delta / @interval_seconds))
      @counters[stream_id][:value] = alpha/time_delta + (1-alpha) * @counters[stream_id][:value]
    else
      @counters[stream_id] = {:timestamp => event_time, :value => 0}
    end
    logger.debug("Current EWMA: #{@counters[stream_id][:value]}", :event => event, :stream_id => stream_id)
    @counters[stream_id][:value]
  end

  def prepare_COUNT
    @counters = Hash.new { |h,k| h[k] = Array.new } 
  end

  def rate_COUNT(event, stream_id, event_time)
    now = ::LogStash::Time.now_f
    @counters[stream_id].delete_if { |e| e < now - @interval_seconds } if @counters[stream_id].any?
    @counters[stream_id].push event_time
    value = @counters[stream_id].count.to_f / @interval_seconds
    logger.debug("Current rate: #{value}", :event => event, :stream_id => stream_id)
    value
  end

end # class LogStash::Filters::Rate
