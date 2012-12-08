require "logstash/filters/base"
require "logstash/namespace"

# Anonymize fields using by replacing values with a consistent hash.
class LogStash::Filters::Anonymize < LogStash::Filters::Base
  config_name "anonymize"
  plugin_status "experimental"

  # The fields to be anonymized
  config :fields, :validate => :array, :required => true

  # Hashing key
  config :key, :validate => :string, :required => true

  # digest type
  config :algorithm, :validate => ['SHA', 'SHA1', 'SHA224', 'SHA256', 'SHA384', 'SHA512', 'MD4', 'MD5', "MURMUR3", "IPV4_NETWORK"], :required => true, :default => 'SHA1'

  public
  def register
    # require any library and set the anonymize function
    case @algorithm
    when "IPV4_NETWORK"
      require "ipaddress"
      class << self; alias_method :anonymize, :anonymize_ipv4_network; end
    when "MURMUR3"
      require "murmurhash3"
      class << self; alias_method :anonymize, :anonymize_murmur3; end
    else
      require 'openssl'
      class << self; alias_method :anonymize, :anonymize_openssl; end
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    @fields.each do |field|
      event[field] = anonymize(event[field])
    end
  end # def filter

  private
  def anonymize_ipv4_network(ip_string)
    warn "ipv4"
    ip = IPAddress::IPv4.new(ip_string)
    ip.prefix = @key
    ip.network.to_s
  end  

  def anonymize_openssl(data)
    warn "openssl"
    digest = algorithm()
    OpenSSL::HMAC.hexdigest(digest, @key, data)
  end

  def anonymize_murmur3(value)
    warn "murmur3"
    case value
    when Fixnum
      MurmurHash3::V32.int_hash(value)
    when String
      MurmurHash3::V32.str_hash(value)
    end
  end

  def algorithm
 
   case @algorithm
      when 'SHA'
        return OpenSSL::Digest::SHA.new
      when 'SHA1'
        return OpenSSL::Digest::SHA1.new
      when 'SHA224'
        return OpenSSL::Digest::SHA224.new
      when 'SHA256'
        return OpenSSL::Digest::SHA256.new
      when 'SHA384'
        return OpenSSL::Digest::SHA384.new
      when 'SHA512'
        return OpenSSL::Digest::SHA512.new
      when 'MD4'
        return OpenSSL::Digest::MD4.new
      when 'MD5'
        return OpenSSL::Digest::MD5.new
      else
        @logger.error("Unknown algorithm")
    end
  end
      
end # class LogStash::Filters::Anonymize
