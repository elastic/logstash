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

  # Reverse resolve one or more fields.
  config :reverse, :validate => :array, :deprecated => "Please use the source and target options."

  # Forward resolve one or more fields.
  config :resolve, :validate => :array, :deprecated => "Please use the source and target options."

  # Determine what action to do: append or replace the values in the fields
  # specified under "reverse" and "resolve."
  config :action, :validate => [ "append", "replace" ], :default => "append",
    :deprecated => "Please use the source and target options."

  # The field containing the hostname or ip address to look up.
  # Use of source/target and reverse/resolve/action is mutually exclusive,
  # source/target take precedence.
  config :source, :validate => :string

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

    if @source
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

    else
      # 'Old' functionality, remove when deprecating resolve, reverse and action
      if @resolve
        begin
          status = Timeout::timeout(@timeout) { 
            resolve(event)
          }
        rescue Timeout::Error
          @logger.debug("DNS: resolve action timed out")
          return
        end
      end

      if @reverse
        begin
          status = Timeout::timeout(@timeout) { 
            reverse(event)
          }
        rescue Timeout::Error
          @logger.debug("DNS: reverse action timed out")
          return
        end
      end
      # Remove until here (and remove the if/else block)
    end

    filter_matched(event)
  end

  # When deprecating, these functions can be deleted
  private
  def resolve(event)
    @resolve.each do |field|
      is_array = false
      raw = event[field]
      if raw.is_a?(Array)
        is_array = true
        if raw.length > 1
          @logger.warn("DNS: skipping resolve, can't deal with multiple values", :field => field, :value => raw)
          return
        end
        raw = raw.first
      end

      begin
        # in JRuby 1.7.11 outputs as US-ASCII
        address = @resolv.getaddress(raw).force_encoding(Encoding::UTF_8)
      rescue Resolv::ResolvError
        @logger.debug("DNS: couldn't resolve the hostname.",
                      :field => field, :value => raw)
        return
      rescue Resolv::ResolvTimeout
        @logger.debug("DNS: timeout on resolving the hostname.",
                      :field => field, :value => raw)
        return
      rescue SocketError => e
        @logger.debug("DNS: Encountered SocketError.",
                      :field => field, :value => raw)
        return
      rescue NoMethodError => e
        # see JRUBY-5647
        @logger.debug("DNS: couldn't resolve the hostname.",
                      :field => field, :value => raw,
                      :extra => "NameError instead of ResolvError")
        return
      end

      if @action == "replace"
        if is_array
          event[field] = [address]
        else
          event[field] = address
        end
      else
        if !is_array
          event[field] = [event[field], address]
        else
          event[field] << address
        end
      end

    end
  end

  private
  def reverse(event)
    @reverse.each do |field|
      raw = event[field]
      is_array = false
      if raw.is_a?(Array)
          is_array = true
          if raw.length > 1
            @logger.warn("DNS: skipping reverse, can't deal with multiple values", :field => field, :value => raw)
            return
          end
          raw = raw.first
      end

      if ! @ip_validator.match(raw)
        @logger.debug("DNS: not an address",
                      :field => field, :value => event[field])
        return
      end
      begin
        # in JRuby 1.7.11 outputs as US-ASCII
        hostname = @resolv.getname(raw).force_encoding(Encoding::UTF_8)
      rescue Resolv::ResolvError
        @logger.debug("DNS: couldn't resolve the address.",
                      :field => field, :value => raw)
        return
      rescue Resolv::ResolvTimeout
        @logger.debug("DNS: timeout on resolving address.",
                      :field => field, :value => raw)
        return
      rescue SocketError => e
        @logger.debug("DNS: Encountered SocketError.",
                      :field => field, :value => raw)
        return
      end

      if @action == "replace"
        if is_array
          event[field] = [hostname]
        else
          event[field] = hostname
        end
      else
        if !is_array
          event[field] = [event[field], hostname]
        else
          event[field] << hostname
        end
      end
    end
  end
end # class LogStash::Filters::DNS
