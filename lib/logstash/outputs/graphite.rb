require "logstash/outputs/base"
require "logstash/namespace"
require "socket"

# This output allows you to pull metrics from your logs and ship them to
# graphite. Graphite is an open source tool for storing and graphing metrics.
#
# An example use case: At loggly, some of our applications emit aggregated
# stats in the logs every 10 seconds. Using the grok filter and this output,
# I can capture the metric values from the logs and emit them to graphite.
class LogStash::Outputs::Graphite < LogStash::Outputs::Base
  config_name "graphite"
  plugin_status "beta"

  # The address of the graphite server.
  config :host, :validate => :string, :default => "localhost"

  # The port to connect on your graphite server.
  config :port, :validate => :number, :default => 2003

  # Interval between reconnect attempts to carboon
  config :reconnect_interval, :validate => :number, :default => 2

  # Should metrics be resend on failure?
  config :resend_on_failure, :validate => :boolean, :default => false

  # The metric(s) to use. This supports dynamic strings like %{@source_host}
  # for metric names and also for values. This is a hash field with key 
  # of the metric name, value of the metric value. Example:
  #
  #     [ "%{@source_host}/uptime", %{uptime_1m} " ]
  #
  # The value will be coerced to a floating point value. Values which cannot be
  # coerced will zero (0)
  config :metrics, :validate => :hash, :default => {}

  # Indicate that the event @fields should be treated as metrics and will be sent as is to graphite
  config :fields_are_metrics, :validate => :boolean, :default => false

  # Include only regex matched metric names
  config :include_metrics, :validate => :array, :default => []

  # Exclude regex matched metric names, by default exclude unresolved %{field} strings
  config :exclude_metrics, :validate => :array, :default => [ "%\{[^}]+\}" ]

  # Enable debug output
  config :debug, :validate => :boolean, :default => false

  def register
    @include_metrics.collect!{|regexp| Regexp.new(regexp)}
    @exclude_metrics.collect!{|regexp| Regexp.new(regexp)}
    connect
  end # def register

  def connect
    # TODO(sissel): Test error cases. Catch exceptions. Find fortune and glory.
    begin
      @socket = TCPSocket.new(@host, @port)
    rescue Errno::ECONNREFUSED => e
      @logger.warn("Connection refused to graphite server, sleeping...",
                   :host => @host, :port => @port)
      sleep(@reconnect_interval)
      retry
    end
  end # def connect

  public
  def receive(event)
    return unless output?(event)
    
    # Graphite message format: metric value timestamp\n

    messages = []
    timestamp = event.sprintf("%{+%s}")

    if @fields_are_metrics
      @logger.debug("got metrics event", :metrics => event.fields)
      event.fields.each do |metric,value|

        messages << "#{metric} #{value.to_f} #{timestamp}"
      end
    else
      @metrics.each do |metric, value|
        @logger.debug("processing", :metric => metric, :value => value)
        messages << "#{event.sprintf(metric)} #{event.sprintf(value).to_f} #{timestamp}"
      end
    end

    @include_metrics.each do |regexp|
      messages.select!{|m| m.match(regexp)}
    end

    @exclude_metrics.each do |regexp|
      messages.select!{|m| !m.match(regexp)}
    end

    unless messages.empty?
      message = messages.join("\n")
      @logger.debug("Sending carbon messages", :messages => messages, :host => @host, :port => @port)

      # Catch exceptions like ECONNRESET and friends, reconnect on failure.
      # TODO(sissel): Test error cases. Catch exceptions. Find fortune and glory.
      begin
        @socket.puts(message)
      rescue Errno::EPIPE, Errno::ECONNRESET => e
        @logger.warn("Connection to graphite server died",
                     :exception => e, :host => @host, :port => @port)
        sleep(@reconnect_interval)
        connect
        retry if @resend_on_failure
      end
    end
    
  end # def receive
end # class LogStash::Outputs::Statsd