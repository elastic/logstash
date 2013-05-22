require "date"
require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/time_addon" # should really use the filters/date.rb bits
require "socket"
require "bindata"
require "ipaddr"

class IP4Addr < BinData::Primitive
  endian :big
  uint32 :storage

  def set(val)
    ip = IPAddr.new(val)
    if ! ip.ipv4?
      raise ArgumentError, "invalid IPv4 address `#{val}'"
    end
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
    if ! ip.ipv6?
      raise ArgumentError, "invalid IPv6 address `#{val}'"
    end
    self.storage = ip.to_i
  end

  def get
    IPAddr.new_ntoh((0..7).map { |i|
      (self.storage >> (112 - 16 * i)) & 0xffff
    }.pack('n8')).to_s
  end
end

class MacAddr < BinData::Primitive
  array :bytes, :type => :uint8, :initial_length => 6

  def set(val)
    ints = val.split(/:/).collect { |int| int.to_i(16) }
    self.bytes = ints
  end

  def get
    self.bytes.collect { |byte| byte.to_s(16) }.join(":")
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
  bit2   :sampling_algorithm
  bit14  :sampling_interval
  array  :records, :initial_length => :flow_records do
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
    skip     :length => 1
    uint8    :tcp_flags # Split up the TCP flags maybe?
    uint8    :protocol
    uint8    :src_tos
    uint16   :src_as
    uint16   :dst_as
    uint8    :src_mask
    uint8    :dst_mask
    skip     :length => 1
  end
end

class TemplateFlowset < BinData::Record
  endian :big
  array  :templates, :read_until => lambda { array.num_bytes == flowset_length - 4 } do
    uint16 :template_id
    uint16 :field_count
    array  :fields, :initial_length => :field_count do
      uint16 :field_type
      uint16 :field_length
    end
  end
end

class OptionFlowset < BinData::Record
  endian :big
  uint16 :template_id
  uint16 :scope_length
  uint16 :option_length
  array  :scope_fields, :initial_length => lambda { scope_length / 4 } do
    uint16 :field_type
    uint16 :field_length
  end
  array  :option_fields, :initial_length => lambda { option_length / 4 } do
    uint16 :field_type
    uint16 :field_length
  end
  skip   :length => 2
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
      option_flowset   1
      string           :default, :read_length => lambda { flowset_length - 4 }
    end
  end
end

# https://gist.github.com/joshaven/184837
class Vash < Hash
  def initialize(constructor = {})
    @register ||= {}
    if constructor.is_a?(Hash)
      super()
      merge(constructor)
    else
      super(constructor)
    end
  end

  alias_method :regular_writer, :[]= unless method_defined?(:regular_writer)
  alias_method :regular_reader, :[] unless method_defined?(:regular_reader)

  def [](key)
    sterilize(key)
    clear(key) if expired?(key)
    regular_reader(key)
  end

  def []=(key, *args)
    if args.length == 2
      value, ttl = args[1], args[0]
    elsif args.length == 1
      value, ttl = args[0], 60
    else
      raise ArgumentError, "Wrong number of arguments, expected 2 or 3, received: #{args.length+1}\n"+
                           "Example Usage:  volatile_hash[:key]=value OR volatile_hash[:key, ttl]=value"
    end
    sterilize(key)
    ttl(key, ttl)
    regular_writer(key, value)
  end

  def merge(hsh)
    hsh.map {|key,value| self[sterile(key)] = hsh[key]}
    self
  end

  def cleanup!
    now = Time.now.to_i
    @register.map {|k,v| clear(k) if v < now}
  end

  def clear(key)
    sterilize(key)
    @register.delete key
    self.delete key
  end

  private
  def expired?(key)
    Time.now.to_i > @register[key].to_i
  end

  def ttl(key, secs=60)
    @register[key] = Time.now.to_i + secs.to_i
  end

  def sterile(key)
    String === key ? key.chomp('!').chomp('=') : key.to_s.chomp('!').chomp('=').to_sym
  end

  def sterilize(key)
    key = sterile(key)
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

  # Netflow v9 template cache TTL (minutes)
  config :cache_ttl, :validate => :number, :default => 4000

  public
  def initialize(params)
    super
    BasicSocket.do_not_reverse_lookup = true
  end # def initialize

  public
  def register
    @udp = nil
    @templates = Vash.new()
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
  def uint_field(length)
    # If length is 4, return :uint32, etc.
    ("uint" + (length * 8).to_s).to_sym
  end

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
          ['version', 'flow_seq_num', 'engine_type', 'engine_id', 'sampling_algorithm', 'sampling_interval'].each do |f|
            e[f] = flowset[f]
          end

          # Create fields in the event from each field in the flow record
          record.each_pair do |k,v|
            case k.to_s
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
          case record.flowset_id
          when 0
            # Template flowset
            record.flowset_data.templates.each do |template|
              catch (:field) do
                fields = []
                template.fields.each do |field|
                  # Worlds longest case statement begins...
                  case field.field_type
                  when 1
                    fields << [uint_field(field.field_length), :in_bytes]
                  when 2
                    fields << [uint_field(field.field_length), :in_pkts]
                  when 3
                    fields << [uint_field(field.field_length), :flows]
                  when 4
                    fields << [:uint8, :protocol]
                  when 5
                    fields << [:uint8, :src_tos]
                  when 6
                    fields << [:uint8, :tcp_flags]
                  when 7
                    fields << [:uint16, :l4_src_port]
                  when 8
                    fields << [:ip4_addr, :ipv4_src_addr]
                  when 9
                    fields << [:uint8, :src_mask]
                  when 10
                    fields << [uint_field(field.field_length), :input_snmp]
                  when 11
                    fields << [:uint16, :l4_dst_port]
                  when 12
                    fields << [:ip4_addr, :ipv4_dst_addr]
                  when 13
                    fields << [:uint8, :dst_mask]
                  when 14
                    fields << [uint_field(field.field_length), :output_snmp]
                  when 15
                    fields << [:ip4_addr, :ipv4_next_hop]
                  when 16
                    fields << [uint_field(field.field_length), :src_as]
                  when 17
                    fields << [uint_field(field.field_length), :dst_as]
                  when 18
                    fields << [:ip4_addr, :bgp_ipv4_next_hop]
                  when 19
                    fields << [uint_field(field.field_length), :mul_dst_pkts]
                  when 20
                    fields << [uint_field(field.field_length), :mul_dst_bytes]
                  when 21
                    fields << [:uint32, :last_switched]
                  when 22
                    fields << [:uint32, :first_switched]
                  when 23
                    fields << [uint_field(field.field_length), :out_bytes]
                  when 24
                    fields << [uint_field(field.field_length), :out_pkts]
                  when 25
                    fields << [:uint16, :min_pkt_length]
                  when 26
                    fields << [:uint16, :max_pkg_length]
                  when 27
                    fields << [:ip6_addr, :ipv6_src_addr]
                  when 28
                    fields << [:ip6_addr, :ipv6_dst_addr]
                  when 29
                    fields << [:uint8, :ipv6_src_mask]
                  when 30
                    fields << [:uint8, :ipv6_dst_mask]
                  when 31
                    fields << [:uint24, :ipv6_flow_label]
                  when 32
                    fields << [:uint16, :icmp_type]
                  when 33
                    fields << [:uint8, :mul_igmp_type]
                  when 34
                    fields << [:uint32, :sampling_interval]
                  when 35
                    fields << [:uint8, :sampling_algorithm]
                  when 36
                    fields << [:uint16, :flow_active_timeout]
                  when 37
                    fields << [:uint16, :flow_inactive_timeout]
                  when 38
                    fields << [:uint8, :engine_type]
                  when 39
                    fields << [:uint8, :engine_id]
                  when 40
                    fields << [uint_field(field.field_length), :total_bytes_exp]
                  when 41
                    fields << [uint_field(field.field_length), :total_pkts_exp]
                  when 42
                    fields << [uint_field(field.field_length), :total_flows_exp]
                  when 44
                    fields << [:ip4_addr, :ipv4_src_prefix]
                  when 45
                    fields << [:ip4_addr, :ipv4_dst_prefix]
                  when 56
                    fields << [:mac_addr, :in_src_mac]
                  when 57
                    fields << [:mac_addr, :out_dst_mac]
                  when 80
                    fields << [:mac_addr, :in_dst_mac]
                  when 81
                    fields << [:mac_addr, :out_src_mac]
                  else
                    @logger.warn("Unsupported field type #{field.field_type}")
                    throw :field
                  end
                end
                # We get this far, we have a list of fields
                key = "#{flowset.source_id}|#{client[3]}|#{template.template_id}"
                @templates[key, @cache_ttl] = BinData::Struct.new(:endian => :big, :fields => fields)

                # Purge any expired templates
                @templates.cleanup!
              end
            end
          when 1
            # Options template flowset
          when 256..65535
            # Data flowset
            key = "#{flowset.source_id}|#{client[3]}|#{record.flowset_id}"
            template = @templates[key]

            if ! template
              @logger.warn("No matching template for flow id #{record.flowset_id} from #{client[3]}")
              next
            end

            length = record.flowset_length - 4

            # There should be at most 3 padding bytes
            if ! (length % template.num_bytes).between?(0, 3)
              @logger.warn("Template length doesn't fit cleanly into flowset")
              next
            end

            array = BinData::Array.new(:type => template, :initial_length => length / template.num_bytes)

            records = array.read(record.flowset_data)

            records.each do |r|
              e = to_event(line, source)

              e.timestamp = Time.at(flowset.unix_sec).utc.to_s

              # Fewer fields in the v9 header
              ['version', 'flow_seq_num'].each do |f|
                e[f] = flowset[f]
              end

              r.each_pair do |k,v|
                case k.to_s
                when /_switched$/
                  millis = flowset.uptime - v
                  seconds = flowset.unix_sec - (millis / 1000)
                  # v9 did away with the nanosecs field
                  micros = 1000000 - (millis % 1000)
                  e[k.to_s] = Time.at(seconds, micros).utc.to_s
                else
                  e[k.to_s] = v
                end
              end

              output_queue << e if e
            end
          else
            @logger.warn("Unsupported flowset id #{record.flowset_id}")
          end
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
