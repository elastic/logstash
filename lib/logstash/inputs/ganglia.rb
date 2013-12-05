# encoding: utf-8
require "date"
require "logstash/filters/grok"
require "logstash/filters/date"
require "logstash/inputs/ganglia/gmondpacket"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Read Ganglia packets from the network via UDP.
#
# Ganglia is a distributed monitoring protocol in use by the high-performance computing community.
# For example, Hadoop can use Ganglia as a way to send metrics to logstash and beyond.
# This plugin implements the 3.1 version of the Ganglia protocol.
#
# There are three kinds of Ganglia messages:
#
#   * Metadata Messages:  Packets which describe a metric,
#   * Value Messages: Packets with the value of a metric,
#   * Other Messages: Which we ignore.
#
# The plugin learns about metrics using the Metadata messages and stores them and then generates an
# event when a Value message arrives which combines the values and metadata into a single event.
#
# Metadata event fields:
#
# * dmax: indicates for how long a metric should be retained. Zero means don't expire automatically.
# * tmax: indicates the maximal interval between times that the metric will be generated. 
# * slope: indicate the slope for the lifetime of the metric.
# * units: indicates the units for the value.
# * vtype: indidates the logical type of the value.  One of string|int8|uint8|int16|uint16|int32|uint32|float|double .
#
# Slope values can be one of the following:
#
# * zero - the metric value will never change
# * positive - the metric value will always increase or stay the same
# * negative - the metric value will always decrease or stay the same
# * other - the metric value can increase or decrease
# * unspecified - nobody wants to say
#
# Value event fields:
#
# * name: The name of the metric.  
# * val: The value of the metric.  The type is one of string|int16|uint16|int32|uint32|float|double and is independent of the vtype.
# * log_host: The name of the host generating the metric
# * host: The IP address at which the metric was received 
#
# Fields the plugin currently does not emit that are part of the Ganglia messages:
#
# * tn: a value which is the number of seconds since the metric was last updated. This should be zero unless spoofing is involved.
# * spoof: used to report metrics on behalf of another machine.
# * name2: a metadata nickname for the metric, almost always a duplicate of the name of the metric.
# * extra: A metadata set of key/value pairs of strings used to pass extra information.
# * format: an sprintf style string that could be used to print the value.
#
# Sample Event:
#
#     {"log_host"=>"constoso.com",
#      "name"=>"jvm.metrics.memNonHeapUsedM",
#      "val"=>"22.936615",
#      "dmax"=>0,
#      "tmax"=>60,
#      "slope"=>"both",
#      "units"=>"",
#      "vtype"=>"float",
#      "host"=>"127.0.0.1"
#
# Relevant Links:
#
# * [What is Hadoop Metrics2?](http://blog.cloudera.com/blog/2012/10/what-is-hadoop-metrics2/)
# * [The Ganglia Protocol](http://sourceforge.net/p/ganglia/code/HEAD/tree/trunk/monitor-core/lib/gm_protocol.x)
# * [XDR (External Data Representation)](http://www.ietf.org/rfc/rfc4506.txt)


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
    BasicSocket.do_not_reverse_lookup = true
  end # def initialize

  public
  def register
  end # def register

  public
  def run(output_queue)
    # udp server retries, exceception handling/logging all happens upstairs.
    begin
        udp_listener(output_queue)
    rescue => e
        @logger.warn("Ganglia: udp listener died",
                     :address => "#{@host}:#{@port}", :exception => e,
        :backtrace => e.backtrace)
    end    
  end # def run

  private
  def udp_listener(output_queue)
    @logger.info("Ganglia: Starting udp listener", :address => "#{@host}:#{@port}")

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

      event["log_host"] = data["hostname"]
      # Fields in the data packet itself
      %w{name val}.each do |info|
        event[info] = data[info]
      end
      # Fields that are from MetaData
      %w{dmax tmax slope units}.each do |info|
        event[info] = @metadata[data["name"]][info]
      end
      # Change the Ganglia metadata type to dtype, so the event can be decorated() later.
      event["vtype"] = @metadata[data["name"]]["type"]
      # Let it rip!
      return event
    else
      # Skipping misc packet types
      @logger.debug("Ganglia: ignoring packet that is not meta or data.")
      return nil
    end
  end # def parse_packet
end # class LogStash::Inputs::Ganglia
