# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Read fluentd events over a TCP socket.
#
# Each event is assumed to be supported by the fluent codec.
#
# For example, you can receive logs from fluentd out-forward plugin with:
#
# Logstash configuration:
#
#    input {
#      fluent {
#        port => 4000
#      }
#    }
#
# Fluent configuration:
#
#    <source>
#      type tail
#      format none
#      path /var/log/syslog
#      tag syslog
#    </source>
#    <match syslog>
#      type out_forward
#      <server>
#        name localhost
#        host localhost
#        port 4000
#        weight 100
#      </server>
#    </match>
#
# Notes:
#
# * manually specified codec will not have any effect, as this plugin is already preconfigured with fluent codec
#
class LogStash::Inputs::Fluent < LogStash::Inputs::Base
  config_name "fluent"
  milestone 1

  # The address to listen on.
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on.
  config :port, :validate => :number, :default => 24224

  # Don't add fluent's tag to the event tags
  config :ignore_tag, :validate => :boolean, :default => false

  def initialize(*args)
    super(*args)
    BasicSocket.do_not_reverse_lookup = true
  end
  # def initialize

  public
  def register
    require "logstash/inputs/tcp"
    require "logstash/codecs/fluent"

    codec = LogStash::Codecs::Fluent.new({
      "ignore_tag" => @ignore_tag
    })
    codec.register

    @tcp = LogStash::Inputs::Tcp.new({
      "host" => @host,
      "port" => @port.to_s,
      "codec" => codec
    })
    @tcp.register
  end
  # def register

  public
  def run(output_queue)
    @heartbeat = Thread.new do
      heartbeat_handler
    end
    begin
      @tcp.run(output_queue)
    rescue
      unless @interrupted
        raise
      end
    end
    @heartbeat.join
  end
  # def run

  public
  def teardown
    @interrupted = true
    @heartbeat.raise(LogStash::ShutdownSignal)
    @tcp.teardown
  end
  # def teardown

  private
  def heartbeat_handler
    begin
      @udp.close if @udp && !@udp.closed?

      @udp = UDPSocket.new(Socket::AF_INET)
      @udp.bind(@host, @port)

      loop do
        _, client = @udp.recvfrom(128)
        @logger.debug("Heartbeat received", :client => "#{client[3]}:#{client[1]}")

        @udp.send("\0", 0, client[3], client[1])
      end
    rescue LogStash::ShutdownSignal
      @logger.info("ShutdownSignal caught. Exiting heartbeat listener")
    rescue => e
      unless @interrupted
        @logger.warn("Heartbeat listener died", :exception => e, :backtrace => e.backtrace)
        retry
      end
    ensure
      @udp.close if @udp && !@udp.closed?
    end
  end
  # def heartbeat_handler

end # class LogStash::Inputs::Fluent
