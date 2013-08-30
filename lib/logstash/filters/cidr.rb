require "logstash/filters/base"
require "logstash/namespace"
require "ipaddr"

# The CIDR filter is for checking IP addresses in events against a list of
# network blocks that might contain it. Multiple addresses can be checked
# against multiple networks, any match succeeds. Upon success additional tags
# and/or fields can be added to the event.

class LogStash::Filters::CIDR < LogStash::Filters::Base

  config_name "cidr"
  plugin_status "experimental"

  # The IP address(es) to check with. Example:
  #
  #     filter {
  #       %PLUGIN% {
  #         add_tag => [ "testnet" ]
  #         address => [ "%{src_ip}", "%{dst_ip}" ]
  #         network => [ "192.0.2.0/24" ]
  #       }
  #     }
  config :address, :validate => :array, :default => []

  # The IP network(s) to check against. Example:
  #
  #     filter {
  #       %PLUGIN% {
  #         add_tag => [ "linklocal" ]
  #         address => [ "%{clientip}" ]
  #         network => [ "169.254.0.0/16", "fe80::/64" ]
  #       }
  #     }
  config :network, :validate => :array, :default => []

  public
  def register
    # Nothing
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    address = @address.collect do |a|
      begin
        IPAddr.new(event.sprintf(a))
      rescue ArgumentError => e
        @logger.warn("Invalid IP address, skipping", :address => a, :event => event)
        nil
      end
    end
    address.compact!

    network = @network.collect do |n|
      begin
        IPAddr.new(event.sprintf(n))
      rescue ArgumentError => e
        @logger.warn("Invalid IP network, skipping", :network => n, :event => event)
        nil
      end
    end
    network.compact!

    # Try every combination of address and network, first match wins
    address.product(network).each do |a, n|
      @logger.debug("Checking IP inclusion", :address => a, :network => n)
      if n.include?(a)
        filter_matched(event)
        return
      end
    end
  end # def filter
end # class LogStash::Filters::CIDR
