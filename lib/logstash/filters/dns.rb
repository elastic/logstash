# encoding: utf-8
# DNS Filter
#
# This filter will resolve any IP addresses from a field of your choosing.
#

require "logstash/filters/base"
require "logstash/namespace"

# The DNS filter performs a lookup (either an A record/CNAME record lookup
# or a reverse lookup at the PTR record) on the record specified in the
# "source" field.
#
# The config should look like this:
#
#     filter {
#       dns {
#         source => [ "client_ip" ]
#         target => [ "client_hostname" ]
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
  milestone 2

  # The field containing the hostname or ip address to look up
  config :source, :validate => :string, :required => true

  # The field where the result should be written to.
  config :target, :validate => :string, :default => "dns"

  # Use custom nameserver.
  config :nameserver, :validate => :string

  # resolv calls will be wrapped in a timeout instance
  config :timeout, :validate => :number, :default => 2

  public
  def register
    require "resolv"
    require "timeout"
    if @nameserver.nil?
      @resolv = Resolv.new
    else
      @resolv = Resolv.new(resolvers=[::Resolv::Hosts.new, ::Resolv::DNS.new(:nameserver => [@nameserver], :search => [], :ndots => 1)])
    end

    @ip_validator = Resolv::AddressRegex
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    raw = event[@source]
    if raw.is_a?(Array)
      if raw.length > 1
        @logger.warn("DNS: skipping resolve, can't deal with multiple values", :field => @source, :value => raw)
        return
      end
      raw = raw.first
    end

    result = nil

    begin
      if @ip_validator.match(raw)
        status = Timeout::timeout(@timeout) {
          result = @resolv.getname(raw)
        }
      else
        status = Timeout::timeout(@timeout) {
          result = @resolv.getaddress(raw)
        }
      end
    rescue Resolv::ResolvError
      @logger.debug("DNS: couldn't resolve.",
                    :field => @source, :value => raw)
      return
    rescue Resolv::ResolvTimeout
      @logger.debug("DNS: timeout on resolving.",
                    :field => @source, :value => raw)
      return
    rescue SocketError => e
      @logger.debug("DNS: Encountered SocketError.",
                    :field => @source, :value => raw)
      return
    rescue NoMethodError => e
      # see JRUBY-5647
      @logger.debug("DNS: couldn't resolve the hostname.",
                    :field => @source, :value => raw,
                    :extra => "NameError instead of ResolvError")
      return
    end

    if @target.empty?
      event["dns"] = result
    else
      event[@target] = result
    end

    filter_matched(event)
  end
end # class LogStash::Filters::DNS
