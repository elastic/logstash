require "logstash/outputs/base"
require "logstash/namespace"

# This output lets you aggregate and send metric data to AWS CloudWatch
#
# Configuration is done partly in this output and partly using fields added
# to your events by other input & filter plugins.
#
# Events which do not have a "CW_metric" field will be ignored, so to send
# events to CloudWatch you must at least add the "CW_metric" field to the
# desired events (using grep for example)
#
# Other fields which can be added to events to modify the behavior of this
# plugin are, "CW_namespace", "CW_unit", "CW_value", and the pair of
# "CW_dimensionName" & "CW_dimensionValue".  All of these field names are
# configurable in this output.  See below for details.
#
# You can read more about AWS CloudWatch here: http://aws.amazon.com/cloudwatch/
class LogStash::Outputs::CloudWatch < LogStash::Outputs::Base
  config_name "cloudwatch"
  plugin_status "experimental"

  # Constants
  # aggregate_key members
  DIMENSIONS = "dimensions"
  TIMESTAMP = "timestamp"
  METRIC = "metric"
  COUNT = "count"
  UNIT = "unit"
  SUM = "sum"
  MIN = "min"
  MAX = "max"
  # Units
  COUNT_UNIT = "Count"
  NONE = "None"

  # The AWS Region to send logs to.
  config :region, :validate => :string, :default => "us-east-1"

  # The AWS Access Key ID
  config :access_key, :validate => :string, :required => true

  # The AWS Secret Access Key
  config :secret_key, :validate => :string, :required => true

  # How often to send data to CloudWatch
  # This does not affect the event timestamps, events will always have their
  # actual timestamp (to-the-minute) sent to CloudWatch.
  #
  # Increasing this may reduce the number of CloudWatch API calls, which would
  # reduce costs in heavy usage.
  #
  # See here for allowed values: https://github.com/jmettraux/rufus-scheduler#the-time-strings-understood-by-rufus-scheduler
  config :timeframe, :validate => :string, :default => "1m"

  # How many events to queue before forcing a call to the CloudWatch API ahead of "timeframe" schedule
  # Set this to the number of events-per-timeframe you will be sending to CloudWatch to avoid extra API calls
  config :queue_size, :validate => :number, :default => 10000

  # The default namespace to use for events which do not have a "CW_namespace" field
  config :namespace, :validate => :string, :default => "Logstash"

  # The name of the field used to set a different namespace per event
  config :field_namespace, :validate => :string, :default => "CW_namespace"

  # The default metric name to use for events which do not have a "CW_metricname" field.
  # If this is provided then all events which pass through this output will be aggregated and
  # sent to CloudWatch, so use this carefully.  Furthermore, when providing this option, you
  # will probably want to also restrict events from passing through this output using event
  # type, tag, and field matching
  #
  # At a minimum events must have a "metric name" to be sent to CloudWatch. This can be achieved
  # either by providing a default here, as described above, OR by adding a "CW_metricname" field
  # to the events themselves, as described below.  By default, if no other configuration is
  # provided besides a metric name, then events will be counted (Unit: Count, Value: 1)
  # by their metric name (either this default or from their CW_metricname field)
  config :metricname, :validate => :string

  # The name of the field used to set the metric name on an event
  config :field_metricname, :validate => :string, :default => "CW_metricname"

  # The default unit to use for events which do not have a "CW_unit" field
  config :unit, :validate => :string, :default => COUNT_UNIT

  # The name of the field used to set the unit on an event metric
  config :field_unit, :validate => :string, :default => "CW_unit"

  # The default value to use for events which do not have a "CW_value" field
  # If provided, this must be a string which can be converted to a fload, for example...
  # "1", "2.34", ".5", and "0.67"
  config :value, :validate => :string, :default => "1"

  # The name of the field used to set the value (float) on an event metric
  config :field_value, :validate => :string, :default => "CW_value"

  # The default dimensions [ name, value, ... ] to use for events which do not have a "CW_dimensions" field
  config :dimensions, :validate => :hash

  # The name of the field used to set the dimensions on an event metric
  # this field named here, if present in an event, must have an array of
  # one or more key & value pairs, for example...
  #     add_field => [ "CW_dimensions", "Environment", "CW_dimensions", "prod" ]
  # or, equivalently...
  #     add_field => [ "CW_dimensions", "Environment" ]
  #     add_field => [ "CW_dimensions", "prod" ]
  config :field_dimensions, :validate => :string, :default => "CW_dimensions"

  public
  def register
    require "thread"
    require "rufus/scheduler"
    require "aws"

    AWS.config(
        :access_key_id => @access_key,
        :secret_access_key => @secret_key,
        :cloud_watch_endpoint => "monitoring.#{@region}.amazonaws.com"
    )
    @cw = AWS::CloudWatch.new

    @valid_units = ["Seconds", "Microseconds", "Milliseconds", "Bytes",
                    "Kilobytes", "Megabytes", "Gigabytes", "Terabytes",
                    "Bits", "Kilobits", "Megabits", "Gigabits", "Terabits",
                    "Percent", COUNT_UNIT, "Bytes/Second", "Kilobytes/Second",
                    "Megabytes/Second", "Gigabytes/Second", "Terabytes/Second",
                    "Bits/Second", "Kilobits/Second", "Megabits/Second",
                    "Gigabits/Second", "Terabits/Second", "Count/Second", NONE]

    @event_queue = SizedQueue.new(@queue_size)
    @scheduler = Rufus::Scheduler.start_new
    @job = @scheduler.every @timeframe do
      @logger.info("Scheduler Activated")
      publish(aggregate({}))
    end
  end # def register

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

    return unless (event[@field_metricname] || @metricname)

    if (@event_queue.length >= @event_queue.max)
      @job.trigger
      @logger.warn("Posted to AWS CloudWatch ahead of schedule.  If you see this often, consider increasing the cloudwatch queue_size option.")
    end

    @logger.info("Queueing event", :event => event)
    @event_queue << event
  end # def receive

  private
  def publish(aggregates)
    aggregates.each do |namespace, data|
      @logger.info("Namespace, data: ", :namespace => namespace, :data => data)
      metric_data = []
      data.each do |aggregate_key, stats|
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
        dims = aggregate_key[DIMENSIONS]
        if (dims.is_a?(Array) && dims.length > 0 && (dims.length % 2) == 0)
          new_data[:dimensions] = Array.new
          i = 0
          while (i < dims.length)
            new_data[:dimensions] << {:name => dims[i], :value => dims[i+1]}
            i += 2
          end
        end
        metric_data << new_data
      end # data.each

      begin
        response = @cw.put_metric_data(
            :namespace => namespace,
            :metric_data => metric_data
        )
        @logger.info("Sent data to AWS CloudWatch OK", :namespace => namespace, :metric_data => metric_data)
      rescue Exception => e
        @logger.warn("Failed to send to AWS CloudWatch", :exception => e, :namespace => namespace, :metric_data => metric_data)
        break
      end
    end # aggregates.each
    return aggregates
  end# def publish

  private
  def aggregate(aggregates)
    @logger.info("QUEUE SIZE ", :queuesize => @event_queue.size)
    while !@event_queue.empty? do
      begin
        count(aggregates, @event_queue.pop(true))
      rescue Exception => e
        @logger.warn("Exception!  Breaking count loop", :exception => e)
        break
      end
    end
    return aggregates
  end # def aggregate

  private
  def count(aggregates, event)
    # If the event doesn't declare a namespace, use the default
    fnamespace = field(event, @field_namespace)
    namespace = (fnamespace ? fnamespace : event.sprintf(@namespace))

    funit = field(event, @field_unit)
    unit = (funit ? funit : event.sprintf(@unit))

    fvalue = field(event, @field_value)
    value = (fvalue ? fvalue : event.sprintf(@value))

    # We may get to this point with valid Units but missing value.  Send zeros.
    val = (!value) ? 0.0 : value.to_f

    # Event provides exactly one (but not both) of value or unit
    if ( (fvalue == nil) ^ (funit == nil) )
      @logger.warn("Likely config error: event has one of #{@field_value} or #{@field_unit} fields but not both.", :event => event)
    end

    # If Unit is still not set or is invalid warn about misconfiguration & use NONE
    if (!@valid_units.include?(unit))
      unit = NONE
      @logger.warn("Likely config error: invalid or missing Units (#{unit.to_s}), using '#{NONE}' instead", :event => event)
    end

    if (!aggregates[namespace])
      aggregates[namespace] = {}
    end

    dims = event[@field_dimensions]
    if (dims) # event provides dimensions
      # validate the structure
      if (!dims.is_a?(Array) || dims.length == 0 || (dims.length % 2) != 0)
        @logger.warn("Likely config error: CloudWatch dimensions field (#{dims.to_s}) found which is not a positive- & even-length array.  Ignoring it.", :event => event)
        dims = nil
      end
      # Best case, we get here and exit the conditional because dims...
      # - is an array
      # - with positive length
      # - and an even number of elements
    elsif (@dimensions.is_a?(Hash)) # event did not provide dimensions, but the output has been configured with a default
      dims = @dimensions.flatten.map{|d| event.sprintf(d)} # into the kind of array described just above
    else
      dims = nil
    end

    fmetric = field(event, @field_metricname)
    aggregate_key = {
        METRIC => (fmetric ? fmetric : event.sprintf(@metricname)),
        DIMENSIONS => dims,
        UNIT => unit,
        TIMESTAMP => event.sprintf("%{+YYYY-MM-dd'T'HH:mm:00Z}")
    }

    if (!aggregates[namespace][aggregate_key])
      aggregates[namespace][aggregate_key] = {}
    end

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
  end # def count

  private
  def field(event, fieldname)
    if !event[fieldname]
      return nil
    else
      if event[fieldname].is_a?(Array)
        return event[fieldname][0]
      else
        return event[fieldname]
      end
    end
  end # def field

end # class LogStash::Outputs::CloudWatch
