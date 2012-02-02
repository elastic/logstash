require "logstash/outputs/base"
require "logstash/namespace"
require "json"

# This output ships metrics to MetricCatcher, allowing you to
# utilize Coda Hale's Metrics.
#
# At Clearspring, we use it to count the response codes from Apache logs
class LogStash::Outputs::MetricCatcher < LogStash::Outputs::Base
  config_name "metriccatcher"
  plugin_status "beta"

  # The address of the MetricCatcher
  config :host, :validate => :string, :default => "localhost"
  # The port to connect on your MetricCatcher
  config :port, :validate => :number, :default => 1420

  # The metrics to send. This supports dynamic strings like %{@source_host}
  # for metric names and also for values. This is a hash field with key 
  # of the metric name, value of the metric value. Example:
  #
  #   counter => [ "%{@source_host}.apache.hits", "1", "widgets.served.doubled", "2" ]
  #   meter => [ "%{@source_host}.apache.response.%{response}", "1" ]
  #
  # The value will be coerced to a floating point value. Values which cannot be
  # coerced will zero (0)
  @@metric_types = ["gauge", "counter", "meter", "biased", "uniform", "timer"]
  @@metric_types.each do |metric_type|
    config metric_type, :validate => :hash
  end

  def register
    @socket = UDPSocket.new
  end # def register

  public
  def receive(event)
    return unless output?(event)

    @@metric_types.each do |metric_type|
      if instance_variable_defined?("@#{metric_type}")
        instance_variable_get("@#{metric_type}").each do |metric_name, metric_value|
          message = [{
            "name"      => event.sprintf(metric_name),
            "type"      => event.sprintf(metric_type),
            "value"     => event.sprintf(metric_value).to_f,
            "timestamp" => event.sprintf("%{+%s}.") + Time.now.usec.to_s
          }]

          @socket.send(message.to_json, 0, @host, @port)
        end # instance_variable_get("@#{metric_type}").each_slice
      end # if
    end # @metric_types.each
  end # def receive
end # class LogStash::Outputs::MetricCatcher
