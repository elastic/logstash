# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# This output allows you to pull metrics from your logs and ship them to
# ganglia's gmond. This is heavily based on the graphite output.
class LogStash::Outputs::Ganglia < LogStash::Outputs::Base
  config_name "ganglia"
  milestone 2

  # The address of the ganglia server.
  config :host, :validate => :string, :default => "localhost"

  # The port to connect on your ganglia server.
  config :port, :validate => :number, :default => 8649

  # The metric to use. This supports dynamic strings like `%{host}`
  config :metric, :validate => :string, :required => true

  # The value to use. This supports dynamic strings like `%{bytes}`
  # It will be coerced to a floating point value. Values which cannot be
  # coerced will zero (0)
  config :value, :validate => :string, :required => true

  # The type of value for this metric.
  config :metric_type, :validate => %w{string int8 uint8 int16 uint16 int32 uint32 float double},
    :default => "uint8"

  # Gmetric units for metric, such as "kb/sec" or "ms" or whatever unit
  # this metric uses.
  config :units, :validate => :string, :default => ""

  # Maximum time in seconds between gmetric calls for this metric.
  config :max_interval, :validate => :number, :default => 60

  # Lifetime in seconds of this metric
  config :lifetime, :validate => :number, :default => 300

  # Metric group
  config :group, :validate => :string, :default => ""

  # Metric slope, represents metric behavior
  config :slope, :validate => %w{zero positive negative both unspecified}, :default => "both"

  def register
    require "gmetric"
  end # def register

  public
  def receive(event)
    return unless output?(event)

    # gmetric only takes integer values, so convert it to int.
    case @metric_type
      when "string"
        localvalue = event.sprintf(@value)
      when "float"
        localvalue = event.sprintf(@value).to_f
      when "double"
        localvalue = event.sprintf(@value).to_f
      else # int8|uint8|int16|uint16|int32|uint32
        localvalue = event.sprintf(@value).to_i
    end
    Ganglia::GMetric.send(@host, @port, {
      :name => event.sprintf(@metric),
      :units => @units,
      :type => @metric_type,
      :value => localvalue,
      :group => @group,
      :slope => @slope,
      :tmax => @max_interval,
      :dmax => @lifetime
    })
  end # def receive
end # class LogStash::Outputs::Ganglia
