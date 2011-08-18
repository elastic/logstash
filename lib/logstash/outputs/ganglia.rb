require "logstash/outputs/base"
require "logstash/namespace"

# This output allows you to pull metrics from your logs and ship them to
# ganglia's gmond. This is heavily based on the graphite output.
class LogStash::Outputs::Ganglia < LogStash::Outputs::Base
  config_name "ganglia"

  # The address of the graphite server.
  config :host, :validate => :string, :default => "localhost"

  # The port to connect on your graphite server.
  config :port, :validate => :number, :default => 8649

  # The metric to use. This supports dynamic strings like %{@source_host}
  config :metric, :validate => :string, :required => true

  # The value to use. This supports dynamic strings like %{bytes}
  # It will be coerced to a floating point value. Values which cannot be
  # coerced will zero (0)
  config :value, :validate => :string, :required => true

  # Gmetric type
  config :type, :validate => :string, :default => "uint8"

  # Gmetric units for metric, such as "kb/sec" or "ms" or whatever unit
  # this metric uses.
  config :units, :validate => :string, :default => ""

  # Maximum time in seconds between gmetric calls for this metric.
  config :tmax, :validate => :number, :default => 60

  # Lifetime in seconds of this metric
  config :dmax, :validate => :number, :default => 300

  def register
    require "gmetric"
  end # def register

  public
  def receive(event)
    # gmetric only takes integer values, so convert it to int.
    case @type
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
      :type => @type,
      :value => localvalue,
      :tmax => @tmax,
      :dmax => @dmax
    })
  end # def receive
end # class LogStash::Outputs::Ganglia
