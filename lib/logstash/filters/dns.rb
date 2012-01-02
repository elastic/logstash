# DNS Filter
#
# This filter will resolve any IP addresses from a field of your choosing.
#

require "logstash/filters/base"
require "logstash/namespace"

# The DNS filter performs a lookup (either an A record/CNAME record lookup
# or a reverse lookup at the PTR record) on records specified under the
# "reverse" and "resolve" arrays.
#
# The config should look like this:
#
#     filter {
#       dns {
#         type => 'type'
#         reverse => [ "@source_host", "field_with_address" ]
#         resolve => [ "field_with_fqdn" ]
#         action => "replace"
#       }
#     }
#
# Caveats: at the moment, there's no way to tune the timeout with the 'resolv'
# core library.  It does seem to be fixed in here:
#
#   http://redmine.ruby-lang.org/issues/5100
#
# but isn't currently in JRuby.
class LogStash::Filters::DNS < LogStash::Filters::Base

  config_name "dns"

  # Reverse resolve one or more fields.
  config :reverse, :validate => :array

  # Forward resolve one or more fields.
  config :resolve, :validate => :array

  # Determine what action to do: append or replace the values in the fields
  # specified under "reverse" and "resolve."
  config :action, :validate => [ "append", "replace" ], :require => true

  public
  def register
    require "resolv"

    @ip_validator = Resolv::AddressRegex
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    resolve(event) if @resolve
    reverse(event) if @reverse

    filter_matched(event)
  end

  private
  def resolve(event)
    @resolve.each do |field|
      begin
        address = Resolv.getaddress(event[field])
      rescue Resolv::ResolvError
        @logger.debug("DNS: couldn't resolve the hostname. Field: #{field}, hostname: #{event[field]}")
        return
      rescue Resolv::ResolvTimeout
        @logger.debug("DNS: timeout on resolving the hostname. Field: #{field}, hostname: #{event[field]}")
        return
      rescue SocketError => e
        @logger.debug("DNS: Encountered SocketError. Field: #{field}, hostname: #{event[field]} error: #{e}")
        return
      end
      if @action == "replace"
        event[field] = address
      else
        event[field] << address
      end
    end
  end

  private
  def reverse(event)
    @reverse.each do |field|
      if ! @ip_validator.match(event[field]) 
        @logger.debug("DNS: not an address: #{event[field]}")
        return
      end
      begin
        hostname = Resolv.getname(event[field])
      rescue Resolv::ResolvError
        @logger.debug("DNS: couldn't resolve the address. Field: #{field}, IP: #{event[field]}")
        return
      rescue Resolv::ResolvTimeout
        @logger.debug("DNS: timeout on resolving address. Field: #{field}, IP: #{event[field]}")
        return
      rescue SocketError => e
        @logger.debug("DNS: Encountered SocketError. Field: #{field}, IP: #{event[field]}, error: #{e}")
        return
      end
      if @action == "replace"
        event[field] = hostname
      else
        event[field] << hostname
      end
    end
  end
end # class LogStash::Filters::DNS
