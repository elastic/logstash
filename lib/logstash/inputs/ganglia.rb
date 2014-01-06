# encoding: utf-8
require "date"
require "logstash/filters/grok"
require "logstash/filters/date"
require "logstash/inputs/ganglia/gmondpacket"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Read ganglia packets from the network via udp
#
class LogStash::Inputs::Ganglia < LogStash::Inputs::Base
  config_name "ganglia"
  milestone 1

  default :codec, "plain"

  # The address to listen on
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on. Remember that ports less than 1024 (privileged
  # ports) may require root to use.
  config :port, :validate => :number, :default => 8649

  public
  def initialize(params)
    super
    @shutdown_requested = false
    BasicSocket.do_not_reverse_lookup = true
  end # def initialize

  public
  def register
  end # def register

  public
  def run(output_queue)
    begin
      udp_listener(output_queue)
    rescue => e
      if !@shutdown_requested
        @logger.warn("ganglia udp listener died",
                     :address => "#{@host}:#{@port}", :exception => e,
        :backtrace => e.backtrace)
        sleep(5)
        retry
      end
    end # begin
  end # def run

  private
  def udp_listener(output_queue)
    @logger.info("Starting ganglia udp listener", :address => "#{@host}:#{@port}")

    if @udp
      @udp.close_read
      @udp.close_write
    end

    @udp = UDPSocket.new(Socket::AF_INET)
    @udp.bind(@host, @port)

    @metadata = Hash.new if @metadata.nil?
    loop do
      packet, client = @udp.recvfrom(9000)
      # TODO(sissel): make this a codec...
      e = parse_packet(packet)
      unless e.nil?
        decorate(e)
        e["host"] = client[3] # the IP address
        output_queue << e
      end
    end
  ensure
    close_udp
  end # def udp_listener

  private

  public
  def teardown
    @shutdown_requested = true
    close_udp
    finished
  end

  private
  def close_udp
    if @udp
      @udp.close_read rescue nil
      @udp.close_write rescue nil
    end
    @udp = nil
  end

  public
  def parse_packet(packet)
    gmonpacket=GmonPacket.new(packet)
    if gmonpacket.meta?
      # Extract the metadata from the packet
      meta=gmonpacket.parse_metadata
      # Add it to the global metadata of this connection
      @metadata[meta['name']]=meta

      # We are ignoring meta events for putting things on the queue
      @logger.debug("received a meta packet", @metadata)
      return nil
    elsif gmonpacket.data?
      data=gmonpacket.parse_data(@metadata)

      # Check if it was a valid data request
      return nil unless data

      event=LogStash::Event.new

      data["program"] = "ganglia"
      event["log_host"] = data["hostname"]
      %w{dmax tmax slope type units}.each do |info|
        event[info] = @metadata[data["name"]][info]
      end
      return event
    else
      # Skipping unknown packet types
      return nil
    end
  end # def parse_packet
end # class LogStash::Inputs::Ganglia
