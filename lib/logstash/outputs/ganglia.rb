require "logstash/outputs/base"
require "logstash/namespace"
require "gmetric"

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

  # Gmetric units for metric
  config :units, :validate => :string, :default => ""

  # Timing values, can be left alone
  config :tmax, :validate => :number, :default => 60
  config :dmax, :validate => :number, :default => 300

  def register
    # No register action required, stateless
  end # def register

  def connect
    # No "connect" action required, stateless
  end # def connect

  public
  def receive(event)
    Ganglia::GMetric.send(@host, @port, {
      :name => @metric,
      :units => @units,
      :type => @type,
      :value => @value,
      :tmax => @tmax,
      :dmax => @dmax
    })
  end # def receive
end # class LogStash::Outputs::Ganglia
