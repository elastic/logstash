require "logstash/outputs/base"
require "logstash/namespace"
require "socket"

# This output allows you to pull metrics from your logs and ship them to
# graphite. Graphite is an open source tool for storing and graphing metrics.
#
# An example use case: At loggly, some of our applications emit aggregated
# stats in the logs every 10 seconds. Using the grok filter and this output,
# I can capture the metric values from the logs and emit them to graphite.
#
# TODO(sissel): Figure out how to manage multiple metrics coming from the same
# event.
class LogStash::Outputs::Graphite < LogStash::Outputs::Base
  config_name "graphite"

  # The address of the graphite server.
  config :host, :validate => :string, :default => "localhost"

  # The port to connect on your graphite server.
  config :port, :validate => :number, :default => 2003

  # The metric to use. This supports dynamic strings like %{@source_host}
  # TODO(sissel): This should probably be an array.
  config :metric, :validate => :string, :required => true

  # The value to use. This supports dynamic strings like %{bytes}
  # It will be coerced to a floating point value. Values which cannot be
  # coerced will zero (0)
  config :value, :validate => :string, :required => true

  def register
    # TODO(sissel): Retry on failure.
    @socket = connect
  end # def register

  def connect
    # TODO(sissel): Test error cases. Catch exceptions. Find fortune and glory.
    socket = TCPSocket.new(@host, @port)
  end # def connect

  public
  def receive(event)
    # Graphite message format: metric value timestamp\n
    message = [event.sprintf(@metric), event.sprintf(@value).to_f,
               event.sprintf("%{+%s}")].join(" ")
    # TODO(sissel): Test error cases. Catch exceptions. Find fortune and glory.
    @socket.puts(message)

    # TODO(sissel): retry on failure TODO(sissel): Make 'retry on failure'
    # tunable; sometimes it's OK to drop metrics.
  end # def receive
end # class LogStash::Outputs::Statsd
