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
  config :algorithm, :validate => ['SHA', 'SHA1', 'SHA224', 'SHA256', 'SHA384', 'SHA512', 'MD4', 'MD5'], :required => true, :default => 'SHA1'

  public
  def register
    # require any library
    require 'openssl'
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    @fields.each do |field|
      event[field] = anonymize(event[field])
    end
  end # def filter

  private
  def anonymize(data)
    digest = algorithm()
    OpenSSL::HMAC.hexdigest(digest, @key, data)
  end

  private
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
