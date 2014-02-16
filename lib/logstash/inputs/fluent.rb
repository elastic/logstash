# encoding: utf-8
require 'logstash/inputs/base'
require 'logstash/namespace'

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
  config_name 'fluent'
  milestone 1

  # The address to listen on.
  config :host, :validate => :string, :default => '0.0.0.0'

  # The port to listen on.
  config :port, :validate => :number, :required => true

  # The 'read' timeout in seconds. If a particular tcp connection is idle for
  # more than this timeout period, we will assume it is dead and close it.
  #
  # If you never want to timeout, use -1.
  config :data_timeout, :validate => :number, :default => -1

  def initialize(*args)
    super(*args)
  end
  # def initialize

  public
  def register
    require 'logstash/inputs/tcp'

    @tcp = LogStash::Inputs::Tcp.new({
      'host' => @host,
      'port' => @port.to_s,
      'data_timeout' => @data_timeout.to_s,
      'codec' => self.class.config_name
    })
    @tcp.register
  end
  # def register

  public
  def run(output_queue)
    @heartbeat = Thread.new do
      heartbeat_handler
    end
    @tcp.run(output_queue)
  end
  # def run

  public
  def teardown
    @tcp.teardown
    @heartbeat.raise(LogStash::ShutdownSignal)
  end
  # def teardown

  private
  def heartbeat_handler
    require 'socket'

    begin
      if @udp && ! @udp.closed?
        @udp.close
      end

      @udp = UDPSocket.new(Socket::AF_INET)
      @udp.bind(@host, @port)

      loop do
        _, client = @udp.recvfrom(128)
        @logger.debug('Heartbeat received', :client => "#{client[3]}:#{client[1]}")

        @udp.send "\0", 0, client[3], client[1]
      end
    rescue LogStash::ShutdownSignal
      @logger.info('ShutdownSignal caught. Exiting heartbeat listener')
    rescue => e
      @logger.warn('Heartbeat listener died', :exception => e, :backtrace => e.backtrace)
      retry
    ensure
      @udp.close if @udp && !@udp.closed?
    end
  end
  # def heartbeat_handler

end # class LogStash::Inputs::Fluent
