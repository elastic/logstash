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

  # The metric(s) to use. This supports dynamic strings like %{@source_host}
  # for metric names and also for values. This is a hash field with key 
  # of the metric name, value of the metric value. Example:
  #
  #     [ "%{@source_host}/uptime", %{uptime_1m} " ]
  #
  # The value will be coerced to a floating point value. Values which cannot be
  # coerced will zero (0)
  config :metrics, :validate => :hash, :required => true

  # Enable debug output
  config :debug, :validate => :boolean, :default => false

  def register
    connect
  end # def register

  def connect
    # TODO(sissel): Test error cases. Catch exceptions. Find fortune and glory.
    begin
      @socket = TCPSocket.new(@host, @port)
    rescue Errno::ECONNREFUSED => e
      @logger.warn("Connection refused to graphite server, sleeping...",
                   :host => @host, :port => @port)
      sleep(2)
      retry
    end
  end # def connect

  public
  def receive(event)
    return unless output?(event)

    # Graphite message format: metric value timestamp\n

    # Catch exceptions like ECONNRESET and friends, reconnect on failure.
    @metrics.each do |metric, value|
      @logger.debug("processing", :metric => metric, :value => value)

      message = [event.sprintf(metric), event.sprintf(value).to_f,
                 event.sprintf("%{+%s}")].join(" ")

      @logger.debug("Sending carbon message", :message => message, :host => @host, :port => @port)

      # TODO(sissel): Test error cases. Catch exceptions. Find fortune and glory.
      begin
        @socket.puts(message)
      rescue Errno::EPIPE, Errno::ECONNRESET => e
        @logger.warn("Connection to graphite server died",
                     :exception => e, :host => @host, :port => @port)
        sleep(2)
        connect
      end

      # TODO(sissel): resend on failure 
      # TODO(sissel): Make 'resend on failure' tunable; sometimes it's OK to
      # drop metrics.
    end # @metrics.each
  end # def receive
end # class LogStash::Outputs::Statsd
