require "logstash/filters/base"
require "logstash/namespace"
require "bindata"
require "ipaddr"

class IP4Addr < BinData::Primitive
  endian :big
  uint32 :storage

  def set(val)
    ip = IPAddr.new(val)
    if ! ip.ipv4?
      raise ArgumentError, "invalid IPv4 address '#{val}'"
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
    skip     :length => 2
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
  array  :templates, :read_until => lambda { flowset_length - 4 - array.num_bytes <= 2 } do
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
  end
  skip   :length => lambda { templates.length.odd? ? 2 : 0 }
end

class Netflow9PDU < BinData::Record
  endian :big
  uint16 :version
  uint16 :flow_records
  uint32 :uptime
  uint32 :unix_sec
  uint32 :flow_seq_num
  uint32 :source_id
  array  :records, :read_until => :eof do
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

class LogStash::Filters::Netflow < LogStash::Filters::Base

  config_name "netflow"
  milestone 1

  # Netflow v9 template cache TTL (minutes)
  config :cache_ttl, :validate => :number, :default => 4000

  public
  def initialize(params)
    super(params)

    @threadsafe = false
  end

  public
  def register
    @templates = Vash.new()
  end # def register

  public
  def filter(event)
    header = Header.read(event["message"])

    if header.version == 5
      flowset = Netflow5PDU.read(event["message"])
    elsif header.version == 9
      flowset = Netflow9PDU.read(event["message"])
    else
      @logger.warn("Unsupported Netflow version v#{header.version}")
      return
    end

    flowset.records.each do |record|
      if flowset.version == 5
        clone = event.clone
        clone.message = ""

        # FIXME Probably not doing this right WRT JRuby?
        #
        # The flowset header gives us the UTC epoch seconds along with
        # residual nanoseconds so we can set @timestamp to that easily
        clone.timestamp = Time.at(flowset.unix_sec, flowset.unix_nsec / 1000).utc
        clone['netflow'] = {} if clone['netflow'].nil?

        # Copy some of the pertinent fields in the header to the event
        ['version', 'flow_seq_num', 'engine_type', 'engine_id', 'sampling_algorithm', 'sampling_interval', 'flow_records'].each do |f|
          clone['netflow'][f] = flowset[f]
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
            clone['netflow'][k.to_s] = Time.at(seconds, micros).utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")
          else
            clone['netflow'][k.to_s] = v
          end
        end

        filter_matched(clone)
        yield clone
      elsif flowset.version == 9
        case record.flowset_id
        when 0
          # Template flowset
          record.flowset_data.templates.each do |template|
            catch (:field) do
              fields = []
              template.fields.each do |field|
                entry = netflow_field_for(field.field_type, field.field_length)
                if ! entry
                  throw :field
                end
                fields += entry
              end
              # We get this far, we have a list of fields
              key = "#{flowset.source_id}|#{event["source"]}|#{template.template_id}"
              @templates[key, @cache_ttl] = BinData::Struct.new(:endian => :big, :fields => fields)
              # Purge any expired templates
              @templates.cleanup!
            end
          end
        when 1
          # Options template flowset
          record.flowset_data.templates.each do |template|
            catch (:field) do
              fields = []
              template.option_fields.each do |field|
                entry = netflow_field_for(field.field_type, field.field_length)
                if ! entry
                  throw :field
                end
                fields += entry
              end
              # We get this far, we have a list of fields
              key = "#{flowset.source_id}|#{event["source"]}|#{template.template_id}"
              @templates[key, @cache_ttl] = BinData::Struct.new(:endian => :big, :fields => fields)
              # Purge any expired templates
              @templates.cleanup!
            end
          end 
        when 256..65535
          # Data flowset
          key = "#{flowset.source_id}|#{event["source"]}|#{record.flowset_id}"
          template = @templates[key]

          if ! template
            @logger.warn("No matching template for flow id #{record.flowset_id} from #{event["source"]}")
            next
          end

          length = record.flowset_length - 4

          # Template shouldn't be longer than the record and there should
          # be at most 3 padding bytes
          if template.num_bytes > length or ! (length % template.num_bytes).between?(0, 3)
            @logger.warn("Template length doesn't fit cleanly into flowset", :template_id => record.flowset_id, :template_length => template.num_bytes, :record_length => length) 
            next
          end

          array = BinData::Array.new(:type => template, :initial_length => length / template.num_bytes)

          records = array.read(record.flowset_data)

          records.each do |r|
            clone = event.clone
            clone.message = ""

            clone.timestamp = Time.at(flowset.unix_sec).utc

            clone['netflow'] = {} if clone['netflow'].nil?

            # Fewer fields in the v9 header
            ['version', 'flow_seq_num'].each do |f|
              clone['netflow'][f] = flowset[f]
            end

            clone['netflow']['flowset_id'] = record.flowset_id

            r.each_pair do |k,v|
              case k.to_s
              when /_switched$/
                millis = flowset.uptime - v
                seconds = flowset.unix_sec - (millis / 1000)
                # v9 did away with the nanosecs field
                micros = 1000000 - (millis % 1000)
                clone['netflow'][k.to_s] = Time.at(seconds, micros).utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")
              else
                clone['netflow'][k.to_s] = v
              end
            end

            filter_matched(clone)
            yield clone
          end
        else
          @logger.warn("Unsupported flowset id #{record.flowset_id}")
        end
      end
    end

    # Drop the original event
    event.cancel
  end # def filter

  private
  def uint_field(length, default)
    # If length is 4, return :uint32, etc. and use default if length is 0
    ("uint" + (((length > 0) ? length : default) * 8).to_s).to_sym
  end # def uint_field

  private
  def netflow_field_for(type, length)
    case type
    when 1
      [[uint_field(length, 4), :in_bytes]]
    when 2
      [[uint_field(length, 4), :in_pkts]]
    when 3
      [[uint_field(length, 4), :flows]]
    when 4
      [[:uint8, :protocol]]
    when 5
      [[:uint8, :src_tos]]
    when 6
      [[:uint8, :tcp_flags]]
    when 7
      [[:uint16, :l4_src_port]]
    when 8
      [[:ip4_addr, :ipv4_src_addr]]
    when 9
      [[:uint8, :src_mask]]
    when 10
      [[uint_field(length, 2), :input_snmp]]
    when 11
      [[:uint16, :l4_dst_port]]
    when 12
      [[:ip4_addr, :ipv4_dst_addr]]
    when 13
      [[:uint8, :dst_mask]]
    when 14
      [[uint_field(length, 2), :output_snmp]]
    when 15
      [[:ip4_addr, :ipv4_next_hop]]
    when 16
      [[uint_field(length, 2), :src_as]]
    when 17
      [[uint_field(length, 2), :dst_as]]
    when 18
      [[:ip4_addr, :bgp_ipv4_next_hop]]
    when 19
      [[uint_field(length, 4), :mul_dst_pkts]]
    when 20
      [[uint_field(length, 4), :mul_dst_bytes]]
    when 21
      [[:uint32, :last_switched]]
    when 22
      [[:uint32, :first_switched]]
    when 23
      [[uint_field(length, 4), :out_bytes]]
    when 24
      [[uint_field(length, 4), :out_pkts]]
    when 25
      [[:uint16, :min_pkt_length]]
    when 26
      [[:uint16, :max_pkg_length]]
    when 27
      [[:ip6_addr, :ipv6_src_addr]]
    when 28
      [[:ip6_addr, :ipv6_dst_addr]]
    when 29
      [[:uint8, :ipv6_src_mask]]
    when 30
      [[:uint8, :ipv6_dst_mask]]
    when 31
      [[:uint24, :ipv6_flow_label]]
    when 32
      [[:uint16, :icmp_type]]
    when 33
      [[:uint8, :mul_igmp_type]]
    when 34
      [[:uint32, :sampling_interval]]
    when 35
      [[:uint8, :sampling_algorithm]]
    when 36
      [[:uint16, :flow_active_timeout]]
    when 37
      [[:uint16, :flow_inactive_timeout]]
    when 38
      [[:uint8, :engine_type]]
    when 39
      [[:uint8, :engine_id]]
    when 40
      [[uint_field(length, 4), :total_bytes_exp]]
    when 41
      [[uint_field(length, 4), :total_pkts_exp]]
    when 42
      [[uint_field(length, 4), :total_flows_exp]]
    when 43 # Vendor specific field
      [[:skip, nil, {:length => length}]]
    when 44
      [[:ip4_addr, :ipv4_src_prefix]]
    when 45
      [[:ip4_addr, :ipv4_dst_prefix]]
    when 46
      [[:uint8, :mpls_top_label_type]]
    when 47
      [[:uint32, :mpls_top_label_ip_addr]]
    when 48
      [[uint_field(length, 4), :flow_sampler_id]]
    when 49
      [[:uint8, :flow_sampler_mode]]
    when 50
      [[:uint32, :flow_sampler_random_interval]]
    when 51 # Vendor specific field
      [[:skip, nil, {:length => length}]]
    when 52
      [[:uint8, :min_ttl]]
    when 53
      [[:uint8, :max_ttl]]
    when 54
      [[:uint16, :ipv4_ident]]
    when 55
      [[:uint8, :dst_tos]]
    when 56
      [[:mac_addr, :in_src_mac]]
    when 57
      [[:mac_addr, :out_dst_mac]]
    when 58
      [[:uint16, :src_vlan]]
    when 59
      [[:uint16, :dst_vlan]]
    when 60
      [[:uint8, :ip_protocol_version]]
    when 61
      [[:uint8, :direction]]
    when 62
      [[:ip6_addr, :ipv6_next_hop]]
    when 63
      [[:ip6_addr, :bgp_ipv6_next_hop]]
    when 64
      [[:uint32, :ipv6_option_headers]]
    when 65..69 # Vendor specific fields
      [[:skip, nil, {:length => length}]]
    when 80
      [[:mac_addr, :in_dst_mac]]
    when 81
      [[:mac_addr, :out_src_mac]]
    when 82
      [[:string, :if_name, {:length => length, :trim_padding => true}]]
    when 83
      [[:string, :if_desc, {:length => length, :trim_padding => true}]]
    else
      @logger.warn("Unsupported field", :type => type, :length => length)
      nil
    end
  end # def netflow_field_for
end # class LogStash::Filters::Netflow
