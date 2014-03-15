# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

#  Fingerprint fields using by replacing values with a consistent hash.
class LogStash::Filters::Fingerprint < LogStash::Filters::Base
  config_name "fingerprint"
  milestone 1

  # Source field(s)
  config :source, :validate => :array, :default => 'message'

  # Target field.
  # will overwrite current value of a field if it exists.
  config :target, :validate => :string, :default => 'fingerprint'

  # When used with IPV4_NETWORK method fill in the subnet prefix length
  # Not required for MURMUR3 or UUID methods
  # With other methods fill in the HMAC key
  config :key, :validate => :string

  # Fingerprint method
  config :method, :validate => ['SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5', "MURMUR3", "IPV4_NETWORK", "UUID", "PUNCTUATION"], :required => true, :default => 'SHA1'

  # When set to true, we concatenate the values of all fields into 1 string like the old checksum filter.
  config :concatenate_sources, :validate => :boolean, :default => false

  def register
    # require any library and set the anonymize function
    case @method
      when "IPV4_NETWORK"
        require 'ipaddr'
        @logger.error("Key value is empty. please fill in a subnet prefix length") if @key.nil?
        class << self; alias_method :anonymize, :anonymize_ipv4_network; end
      when "MURMUR3"
        require "murmurhash3"
        class << self; alias_method :anonymize, :anonymize_murmur3; end
      when "UUID"
        require "securerandom"
      when "PUNCTUATION"
        # nothing required
      else
        require 'openssl'
        @logger.error("Key value is empty. Please fill in an encryption key") if @key.nil?
        class << self; alias_method :anonymize, :anonymize_openssl; end
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    case @method
      when "UUID"
        event[@target] = SecureRandom.uuid
      when "PUNCTUATION"
        @source.sort.each do |field|
          next unless event.include?(field)
          event[@target] = event[field].tr('A-Za-z0-9 \t','')
        end
      else
        if @concatenate_sources
          to_string = ''
          @source.sort.each do |k|
            @logger.debug("Adding key to string")
            to_string << "|#{k}|#{event[k]}"
          end
          to_string << "|"
          @logger.debug("String built", :to_checksum => to_string)
          event[@target] = anonymize(to_string)
        else
          @source.each do |field|
            next unless event.include?(field)
            if event[field].is_a?(Array)
              event[@target] = event[field].collect { |v| anonymize(v) }
            else
              event[@target] = anonymize(event[field])
            end
          end # @source.each
        end # concatenate_sources

    end # casse @method
  end # def filter

  private
  def anonymize_ipv4_network(ip_string)
    # in JRuby 1.7.11 outputs as US-ASCII
    IPAddr.new(ip_string).mask(@key.to_i).to_s.force_encoding(Encoding::UTF_8)
  end

  def anonymize_openssl(data)
    digest = encryption_algorithm()
    # in JRuby 1.7.11 outputs as ASCII-8BIT
    OpenSSL::HMAC.hexdigest(digest, @key, data).force_encoding(Encoding::UTF_8)
  end

  def anonymize_murmur3(value)
    case value
      when Fixnum
        MurmurHash3::V32.int_hash(value)
      when String
        MurmurHash3::V32.str_hash(value)
    end
  end

  def encryption_algorithm
   case @method
     when 'SHA1'
       return OpenSSL::Digest::SHA1.new
     when 'SHA256'
       return OpenSSL::Digest::SHA256.new
     when 'SHA384'
       return OpenSSL::Digest::SHA384.new
     when 'SHA512'
       return OpenSSL::Digest::SHA512.new
     when 'MD5'
       return OpenSSL::Digest::MD5.new
     else
       @logger.error("Unknown algorithm")
    end
  end

end # class LogStash::Filters::Anonymize
