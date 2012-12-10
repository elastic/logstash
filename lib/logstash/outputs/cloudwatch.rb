require "logstash/outputs/base"
require "logstash/namespace"

require "thread"
require "rufus/scheduler"
require "aws"

# Got an AWS account? Use logstash to ship events to CloudWatch!
#
class LogStash::Outputs::CloudWatch < LogStash::Outputs::Base
  config_name "cloudwatch"
  plugin_status "experimental"

  # The AWS Region to send logs to.
  config :region, :validate => :string, :default => "us-east-1"
  config :access_key, :validate => :string, :required => true
  config :secret_key, :validate => :string, :required => true
  config :namespace, :validate => :string, :default => "Logstash"
  config :timeframe, :validate => :string, :default => "1m"
  config :field_namespace, :validate => :string, :default => "CW_namespace"
  config :field_metric, :validate => :string, :default => "CW_metric"
  config :field_unit, :validate => :string, :default => "CW_unit"
  config :field_value, :validate => :string, :default => "CW_value"
  config :field_dimensionname, :validate => :string, :default => "CW_dimensionName"
  config :field_dimensionvalue, :validate => :string, :default => "CW_dimensionValue"

  DIM_VALUE = "dimensionValue"
  DIM_NAME = "dimensionName"
  TIMESTAMP = "timestamp"
  METRIC = "metric"
  UNIT = "unit"
  COUNT = "count"
  SUM = "sum"
  MIN = "min"
  MAX = "max"
  COUNT = "Count"
  NONE = "None"

  public
  def register
    AWS.config(
        :access_key_id => @access_key,
        :secret_access_key => @secret_key,
        :cloud_watch_endpoint => "monitoring.#{@region}.amazonaws.com"
    )
    @cw = AWS::CloudWatch.new

    @valid_units = ["Seconds", "Microseconds", "Milliseconds", "Bytes", "Kilobytes", "Megabytes", "Gigabytes", "Terabytes", "Bits", "Kilobits", "Megabits", "Gigabits", "Terabits", "Percent", COUNT, "Bytes/Second", "Kilobytes/Second", "Megabytes/Second", "Gigabytes/Second", "Terabytes/Second", "Bits/Second", "Kilobits/Second", "Megabits/Second", "Gigabits/Second", "Terabits/Second", "Count/Second", NONE]

    @event_queue = Queue.new
    @scheduler = Rufus::Scheduler.start_new
    @job = @scheduler.every @timeframe do
      @logger.info("Scheduler Activated")
      send(aggregate({}))
    end
  end

  public
  def receive(event)
    return unless output?(event)

    if event == LogStash::SHUTDOWN
      job.trigger()
      job.unschedule()
      @logger.info("CloudWatch aggregator thread shutdown.")
      finished
      return
    end

    return unless event.fields.member?(@field_metric)

    @logger.info("Queueing event", :event => event)
    @event_queue << event
  end # def receive

  private
  def send(aggregates)
    aggregates.each { |namespace, data|
      @logger.info("Namespace, data: ", :namespace => namespace, :data => data)
      metric_data = []
      data.each { |aggregate_key, stats|
        new_data = {
            :metric_name => aggregate_key[METRIC],
            :timestamp => aggregate_key[TIMESTAMP],
            :unit => aggregate_key[UNIT],
            :statistic_values => {
                :sample_count => stats[COUNT],
                :sum => stats[SUM],
                :minimum => stats[MIN],
                :maximum => stats[MAX],
            }
        }
        if (aggregate_key[DIM_NAME] != nil && aggregate_key[DIM_VALUE] != nil)
          new_data[:dimensions] = [{
                                       :name => aggregate_key[DIM_NAME],
                                       :value => aggregate_key[DIM_VALUE]
                                   }]
        end
        metric_data << new_data
      } # data.each

      begin
        response = @cw.put_metric_data(
            :namespace => namespace,
            :metric_data => metric_data
        )
        @logger.info("Sent data to AWS CloudWatch OK")
      rescue Exception => e
        @logger.warn("Failed to send to AWS CloudWatch", :exception => e, :namespace => namespace, :metric_data => metric_data)
        break
      end
    } # aggregates.each
    return aggregates
  end

  # def send

  private
  def aggregate(aggregates)

    @logger.info("QUEUE SIZE ", :queuesize => @event_queue.size)
    until @event_queue.empty? do
      begin
        count(aggregates, @event_queue.pop(true))
      rescue Exception => e
        @logger.warn("Exception!  Breaking count loop", :exception => e)
        break
      end
    end
    return aggregates
  end

  private
  def count(aggregates, event)

    # If the event doesnt declare a namespace, use the default
    ns = field(event, @field_namespace)
    namespace = (!ns) ? @namespace : ns

    unit = field(event, @field_unit)
    value = field(event, @field_value)

    # If neither Units nor Value is set, then we simply count the event
    if (!unit && !value)
      unit = COUNT
      value = "1"
    end

    # If Units is still not set (or is invalid), then we know Value must BE set, so set Units to "None"
    # And warn about misconfiguration
    if (!unit || !@valid_units.include?(unit))
      unit = NONE
      @logger.warn("Possible config error: CloudWatch Value found with invalid or missing Units")
    end


    if (!aggregates[namespace])
      aggregates[namespace] = {}
      @logger.info("INITIALIZING NAMESPACE DATA")
    end

    aggregate_key = {
        METRIC => field(event, @field_metric),
        DIM_NAME => field(event, @field_dimensionname),
        DIM_VALUE => field(event, @field_dimensionvalue),
        UNIT => unit,
        TIMESTAMP => normalizeTimestamp(event.timestamp)
    }

    if (!aggregates[namespace][aggregate_key])
      aggregates[namespace][aggregate_key] = {}
    end

    # We may get to this point with valid Units but missing value.  Send zeros.
    val = (!value) ? 0.0 : value.to_f

    if (!aggregates[namespace][aggregate_key][MAX] || val > aggregates[namespace][aggregate_key][MAX])
      aggregates[namespace][aggregate_key][MAX] = val
    end

    if (!aggregates[namespace][aggregate_key][MIN] || val < aggregates[namespace][aggregate_key][MIN])
      aggregates[namespace][aggregate_key][MIN] = val
    end

    if (!aggregates[namespace][aggregate_key][COUNT])
      aggregates[namespace][aggregate_key][COUNT] = 1
    else
      aggregates[namespace][aggregate_key][COUNT] += 1
    end

    if (!aggregates[namespace][aggregate_key][SUM])
      aggregates[namespace][aggregate_key][SUM] = val
    else
      aggregates[namespace][aggregate_key][SUM] += val
    end
  end

  # Zeros out the seconds in a ISO8601 timestamp like event.timestamp
  public
  def normalizeTimestamp(time)
    tz = (time[-1, 1] == "Z") ? "Z" : time[-5, 5]
    totheminute = time[0..16]
    normal = totheminute + "00.000" + tz
    return normal
  end

  private
  def field(event, fieldname)
    return event.fields.member?(fieldname) ? event.fields[fieldname][0] : nil
  end

end # class LogStash::Outputs::CloudWatch
