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

    # force "plain" format. others don't make sense here.
    @format = "plain"
  end # def initialize

  public
  def register
  end # def register

  public
  def run(output_queue)
    # udp server
    Thread.new do
      LogStash::Util::set_thread_name("input|ganglia|udp")
      begin
        udp_listener(output_queue)
      rescue => e
        break if @shutdown_requested
        @logger.warn("ganglia udp listener died",
                     :address => "#{@host}:#{@port}", :exception => e,
        :backtrace => e.backtrace)
        sleep(5)
        retry
      end # begin
    end # Thread.new

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
      # Ruby uri sucks, so don't use it.
      source = "ganglia://#{client[3]}/"

      e = packet_to_event(packet,source)
      unless e.nil?
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
  def packet_to_event(packet,source)

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
      unless data.nil?

        event=LogStash::Event.new
        #event['@timestamp'] = Time.now.to_i
        event.source = source
        event.type = @config["type"]

        data['program'] = "ganglia"
        event['@fields'] = data
        event['@fields']['log_host'] =  data['hostname']
        %w{dmax tmax slope type units}.each do |info|
          event.fields[info] = @metadata[data['name']][info]
        end
        return event
      end
    else
      # Skipping unknown packet types
      return nil
    end


  end # def packet_to_event
end # class LogStash::Inputs::Ganglia
