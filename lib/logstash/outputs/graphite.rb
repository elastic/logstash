# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "socket"

# This output allows you to pull metrics from your logs and ship them to
# Graphite. Graphite is an open source tool for storing and graphing metrics.
#
# An example use case: Some applications emit aggregated stats in the logs
# every 10 seconds. Using the grok filter and this output, it is possible to
# capture the metric values from the logs and emit them to Graphite.
class LogStash::Outputs::Graphite < LogStash::Outputs::Base
  config_name "graphite"
  milestone 2

  EXCLUDE_ALWAYS = [ "@timestamp", "@version" ]

  DEFAULT_METRICS_FORMAT = "*"
  METRIC_PLACEHOLDER = "*"

  # The hostname or IP address of the Graphite server.
  config :host, :validate => :string, :default => "localhost"

  # The port to connect to on the Graphite server.
  config :port, :validate => :number, :default => 2003

  # Interval between reconnect attempts to Carbon.
  config :reconnect_interval, :validate => :number, :default => 2

  # Should metrics be resent on failure?
  config :resend_on_failure, :validate => :boolean, :default => false

  # The metric(s) to use. This supports dynamic strings like %{host}
  # for metric names and also for values. This is a hash field with key 
  # being the metric name, value being the metric value. Example:
  #
  #     [ "%{host}/uptime", "%{uptime_1m}" ]
  #
  # The value will be coerced to a floating point value. Values which cannot be
  # coerced will be set to zero (0). You may use either `metrics` or `fields_are_metrics`,
  # but not both.
  config :metrics, :validate => :hash, :default => {}

  # An array indicating that these event fields should be treated as metrics
  # and will be sent verbatim to Graphite. You may use either `fields_are_metrics`
  # or `metrics`, but not both.
  config :fields_are_metrics, :validate => :boolean, :default => false

  # Include only regex matched metric names.
  config :include_metrics, :validate => :array, :default => [ ".*" ]

  # Exclude regex matched metric names, by default exclude unresolved %{field} strings.
  config :exclude_metrics, :validate => :array, :default => [ "%\{[^}]+\}" ]

  # Enable debug output.
  config :debug, :validate => :boolean, :default => false, :deprecated => "This setting was never used by this plugin. It will be removed soon."

  # Defines the format of the metric string. The placeholder '*' will be
  # replaced with the name of the actual metric.
  #
  #     metrics_format => "foo.bar.*.sum"
  #
  # NOTE: If no metrics_format is defined, the name of the metric will be used as fallback.
  config :metrics_format, :validate => :string, :default => DEFAULT_METRICS_FORMAT

  def register
    @include_metrics.collect!{|regexp| Regexp.new(regexp)}
    @exclude_metrics.collect!{|regexp| Regexp.new(regexp)}

    if @metrics_format && !@metrics_format.include?(METRIC_PLACEHOLDER)
      @logger.warn("metrics_format does not include placeholder #{METRIC_PLACEHOLDER} .. falling back to default format: #{DEFAULT_METRICS_FORMAT.inspect}")

      @metrics_format = DEFAULT_METRICS_FORMAT
    end

    connect
  end # def register

  def connect
    # TODO(sissel): Test error cases. Catch exceptions. Find fortune and glory. Retire to yak farm.
    begin
      @socket = TCPSocket.new(@host, @port)
    rescue Errno::ECONNREFUSED => e
      @logger.warn("Connection refused to graphite server, sleeping...",
                   :host => @host, :port => @port)
      sleep(@reconnect_interval)
      retry
    end
  end # def connect

  def construct_metric_name(metric)
    if @metrics_format
      return @metrics_format.gsub(METRIC_PLACEHOLDER, metric)
    end

    metric
  end

  public
  def receive(event)
    return unless output?(event)

    # Graphite message format: metric value timestamp\n

    messages = []
    timestamp = event.sprintf("%{+%s}")

    if @fields_are_metrics
      @logger.debug("got metrics event", :metrics => event.to_hash)
      event.to_hash.each do |metric,value|
        next if EXCLUDE_ALWAYS.include?(metric)
        next unless @include_metrics.empty? || @include_metrics.any? { |regexp| metric.match(regexp) }
        next if @exclude_metrics.any? {|regexp| metric.match(regexp)}
        messages << "#{construct_metric_name(metric)} #{event.sprintf(value.to_s).to_f} #{timestamp}"
      end
    else
      @metrics.each do |metric, value|
        @logger.debug("processing", :metric => metric, :value => value)
        metric = event.sprintf(metric)
        next unless @include_metrics.any? {|regexp| metric.match(regexp)}
        next if @exclude_metrics.any? {|regexp| metric.match(regexp)}
        messages << "#{construct_metric_name(event.sprintf(metric))} #{event.sprintf(value).to_f} #{timestamp}"
      end
    end

    if messages.empty?
      @logger.debug("Message is empty, not sending anything to Graphite", :messages => messages, :host => @host, :port => @port)
    else
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
end # class LogStash::Outputs::Graphite
