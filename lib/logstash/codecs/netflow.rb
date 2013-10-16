require "logstash/filters/base"
require "logstash/namespace"

# The "netflow" codec is for decoding Netflow v5/v9 flows.
class LogStash::Codecs::Netflow < LogStash::Codecs::Base
  config_name "netflow"
  milestone 1

  # Netflow v9 template cache TTL (minutes)
  config :cache_ttl, :validate => :number, :default => 4000

  # Specify into what field you want the Netflow data.
  config :target, :validate => :string, :default => "netflow"

  # Specify which Netflow versions you will accept.
  config :versions, :validate => :array, :default => [5, 9]

  public
  def initialize(params={})
    super(params)
    @threadsafe = false
  end

  public
  def register
    require "logstash/codecs/netflow/util"
    @templates = Vash.new()
  end # def register

  public
  def decode(payload, &block)
    header = Header.read(payload)

    unless @versions.include?(header.version)
      @logger.warn("Ignoring Netflow version v#{header.version}")
      return
    end

    if header.version == 5
      flowset = Netflow5PDU.read(payload)
    elsif header.version == 9
      flowset = Netflow9PDU.read(payload)
    else
      @logger.warn("Unsupported Netflow version v#{header.version}")
      return
    end

    flowset.records.each do |record|
      if flowset.version == 5
        event = LogStash::Event.new

        # FIXME Probably not doing this right WRT JRuby?
        #
        # The flowset header gives us the UTC epoch seconds along with
        # residual nanoseconds so we can set @timestamp to that easily
        event["@timestamp"] = Time.at(flowset.unix_sec, flowset.unix_nsec / 1000).utc
        event[@target] = {}

        # Copy some of the pertinent fields in the header to the event
        ['version', 'flow_seq_num', 'engine_type', 'engine_id', 'sampling_algorithm', 'sampling_interval', 'flow_records'].each do |f|
          event[@target][f] = flowset[f]
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
            event[@target][k.to_s] = Time.at(seconds, micros).utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")
          else
            event[@target][k.to_s] = v
          end
        end

        yield event
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
              #key = "#{flowset.source_id}|#{event["source"]}|#{template.template_id}"
              key = "#{flowset.source_id}|#{template.template_id}"
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
              #key = "#{flowset.source_id}|#{event["source"]}|#{template.template_id}"
              key = "#{flowset.source_id}|#{template.template_id}"
              @templates[key, @cache_ttl] = BinData::Struct.new(:endian => :big, :fields => fields)
              # Purge any expired templates
              @templates.cleanup!
            end
          end 
        when 256..65535
          # Data flowset
          #key = "#{flowset.source_id}|#{event["source"]}|#{record.flowset_id}"
          key = "#{flowset.source_id}|#{record.flowset_id}"
          template = @templates[key]

          if ! template
            #@logger.warn("No matching template for flow id #{record.flowset_id} from #{event["source"]}")
            @logger.warn("No matching template for flow id #{record.flowset_id}")
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
            event = LogStash::Event.new(
              "@timestamp" => Time.at(flowset.unix_sec).utc,
              @target => {}
            )

            # Fewer fields in the v9 header
            ['version', 'flow_seq_num'].each do |f|
              event[@target][f] = flowset[f]
            end

            event[@target]['flowset_id'] = record.flowset_id

            r.each_pair do |k,v|
              case k.to_s
              when /_switched$/
                millis = flowset.uptime - v
                seconds = flowset.unix_sec - (millis / 1000)
                # v9 did away with the nanosecs field
                micros = 1000000 - (millis % 1000)
                event[@target][k.to_s] = Time.at(seconds, micros).utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")
              else
                event[@target][k.to_s] = v
              end
            end

            yield event
          end
        else
          @logger.warn("Unsupported flowset id #{record.flowset_id}")
        end
      end
    end
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
