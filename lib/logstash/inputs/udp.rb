require "date"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Read messages as events over the network via udp.
#
class LogStash::Inputs::Udp < LogStash::Inputs::Base
  config_name "udp"
  milestone 2

  # The address to listen on
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on. Remember that ports less than 1024 (privileged
  # ports) may require root to use.
  config :port, :validate => :number, :default => 9999

  # Buffer size
  config :buffer_size, :validate => :number, :default => 8192

  public
  def initialize(params)
    super
    BasicSocket.do_not_reverse_lookup = true
  end # def initialize

  public
  def register
    @udp = nil
  end # def register

  public
  def run(output_queue)
    LogStash::Util::set_thread_name("input|udp|#{@port}")
    begin
      # udp server
      udp_listener(output_queue)
    rescue => e
      @logger.warn("UDP listener died", :exception => e, :backtrace => e.backtrace)
      sleep(5)
      retry
    end # begin
  end # def run

  private
  def udp_listener(output_queue)
    @logger.info("Starting UDP listener", :address => "#{@host}:#{@port}")

    if @udp && ! @udp.closed?
      @udp.close
    end

    @udp = UDPSocket.new(Socket::AF_INET)
    @udp.bind(@host, @port)

    loop do
      line, client = @udp.recvfrom(@buffer_size)
      # Ruby uri sucks, so don't use it.
      source = "udp://#{client[3]}:#{client[1]}/"

      e = to_event(line, source)
      if e
        output_queue << e
      end
    end
  ensure
    if @udp
      @udp.close_read rescue nil
      @udp.close_write rescue nil
    end
  end # def udp_listener

end # class LogStash::Inputs::Udp
