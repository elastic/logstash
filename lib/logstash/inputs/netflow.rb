require "date"
require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/time_addon" # should really use the filters/date.rb bits
require "socket"
require "bindata"
require "ipaddr"
require "stringio"

class IP4Addr < BinData::Primitive
  endian :big
  uint32 :storage

  def set(val)
    ip = IPAddr.new(val)
    self.storage = ip.to_i
  end

  def get
    IPAddr.new_ntoh([self.storage].pack('N')).to_s
  end
end

class IP6Addr < BinData::Primitive
  endian  :big
  uint128 :storage

  def set(val)
    ip = IPAddr.new(val)
    self.storage = ip.to_i
  end

  def get
    IPAddr.new_ntoh((0..7).map { |i|
      (self.storage >> (112 - 16 * i)) & 0xffff
    }.pack('n8')).to_s
  end
end

class Header < BinData::Record
  endian :big
  uint16 :version
end

class Netflow5PDU < BinData::Record
  endian :big
  uint16 :version
  uint16 :flow_records
  uint32 :uptime
  uint32 :unix_sec
  uint32 :unix_nsec
  uint32 :flow_seq_num
  uint8  :engine_type
  uint8  :engine_id
  bit2   :sampling_type
  bit14  :sampling_interval
  array  :records, :initial_length => :flow_records do
    hide     :pad1, :pad2
    ip4_addr :ipv4_src_addr
    ip4_addr :ipv4_dst_addr
    ip4_addr :ipv4_next_hop
    uint16   :input_snmp
    uint16   :output_snmp
    uint32   :in_pkts
    uint32   :in_bytes
    uint32   :first_switched
    uint32   :last_switched
    uint16   :l4_src_port
    uint16   :l4_dst_port
    uint8    :pad1
    uint8    :tcp_flags # Split up the TCP flags maybe?
    uint8    :protocol
    uint8    :src_tos
    uint16   :src_as
    uint16   :dst_as
    uint8    :src_mask
    uint8    :dst_mask
    uint16   :pad2
  end
end

class TemplateFlowset < BinData::Record
  endian :big
  array  :flowset_templates, :read_until => lambda { array.num_bytes == flowset_length - 4 } do
    uint16 :flowset_template_id
    uint16 :flowset_field_count
    array  :flowset_fields, :initial_length => :flowset_field_count do
      uint16 :flowset_field_type
      uint16 :flowset_field_length
    end
  end
end

class Netflow9PDU < BinData::Record
  endian :big
  uint16 :version
  uint16 :flow_records
  uint32 :uptime
  uint32 :unix_sec
  uint32 :flow_seq_num
  uint32 :source_id
  array  :records, :initial_length => :flow_records do
    uint16 :flowset_id
    uint16 :flowset_length
    choice :flowset_data, :selection => :flowset_id do
      template_flowset 0
      string           :default, :read_length => lambda { flowset_length - 4 }
    end
  end
end

# Read messages as events over the network via udp.
#
class LogStash::Inputs::Netflow < LogStash::Inputs::Base
  config_name "netflow"
  plugin_status "experimental"

  # The address to listen on
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on. Remember that ports less than 1024 (privileged
  # ports) may require root to use.
  config :port, :validate => :number, :default => 2055

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
    LogStash::Util::set_thread_name("input|netflow|#{@port}")
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

      header = Header.read(line)

      if header.version == 5
        flowset = Netflow5PDU.read(line)
      elsif header.version == 9
        flowset = Netflow9PDU.read(line)
      else
        @logger.warn("Unsupported Netflow version v#{header.version}")
        next
      end

      flowset.records.each do |record|
        if flowset.version == 5
          # I wonder how much use the original packet is?
          e = to_event(line, source)

          # FIXME Probably not doing this right WRT JRuby?
          #
          # The flowset header gives us the UTC epoch seconds along with
          # residual nanoseconds so we can set @timestamp to that easily
          e.timestamp = Time.at(flowset.unix_sec, flowset.unix_nsec / 1000).utc.to_s

          # Copy some of the pertinent fields in the header to the event
          ['version', 'flow_seq_num', 'engine_type', 'engine_id', 'sampling_type', 'sampling_interval'].each do |f|
            e[f] = flowset[f]
          end

          # Create fields in the event from each field in the flow record
          record.each_pair do |k,v|
            case k.to_s
            when /^pad/
              next # Skip those two pesky pad fields
            when /_switched$/
              # The flow record sets the first and last times to the device
              # uptime in milliseconds. Given the actual uptime is provided
              # in the flowset header along with the epoch seconds we can
              # convert these into absolute times
              millis = flowset.uptime - v
              seconds = flowset.unix_sec - (millis / 1000)
              micros = (flowset.unix_nsec / 1000) - (millis % 1000)
              if micros < 0
                seconds--
                micros += 1000000
              end
              # FIXME Again, probably doing this wrong WRT JRuby?
              e[k.to_s] = Time.at(seconds, micros).utc.to_s
            else
              e[k.to_s] = v
            end
          end

          output_queue << e if e
        elsif flowset.version == 9
          e = to_event(line, source)
        end
      end
    end
  ensure
    if @udp
      @udp.close_read rescue nil
      @udp.close_write rescue nil
    end
  end # def udp_listener

end # class LogStash::Inputs::Netflow
