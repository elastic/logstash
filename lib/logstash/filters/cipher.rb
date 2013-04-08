require "logstash/filters/base"
require "logstash/namespace"

# This filter parses a source and apply a cipher or decipher before
# storing it in the target.
#
class LogStash::Filters::Cipher < LogStash::Filters::Base
  config_name "cipher"
  plugin_status "experimental"

  # The field to perform filter
  #
  # Example, to use the @message field:
  #
  #     filter { cipher { source => "@message" } }
  config :source, :validate => :string, :default => '@message'

  # The name of the container to put the result
  #
  # Example, to place the reqult into crypt :
  #
  #     filter { cipher { target => "crypt" } }
  config :target, :validate => :string, :default => '@message'

  # Do we have to perform a base64 decode or encode?
  #
  # If we are decrypting, base64 decode will be done before.
  # If we are encrypting, base64 will be done after.
  #
  config :base64, :validate => :boolean, :default => true

  # The key to use
  config :key, :validate => :string

  # The key size to pad
  #
  # It depends of the cipher algorythm.I your key don't need
  # padding, don't set this parameter
  #
  # Example, for AES-256, we must have 32 char long key
  #     filter { cipher { key_size => 32 }
  #
  config :key_size, :validate => :number, :default => 32

  # The character used to pad the key
  config :key_pad, :default => "\0"

  # The cipher algorythm
  #
  # A list of supported algorithms can be obtained by
  #
  #     puts OpenSSL::Cipher.ciphers
  config :algorithm, :validate => :string, :required => true

  # Encrypting or decrypting some data
  #
  # Valid values are encrypt or decrypt
  config :mode, :validate => :string, :required => true

  # Cypher padding to use
  #
  # We are using Openssl jRuby which uses default padding to PKCS5Padding
  # If you want to change it, set this paramter. If you want to change
  # it, Set this parameter to 0
  #     filter { cipher { padding => 0 }}
  config :cipher_padding, :validate => :string

  # The initialization vector to use
  #
  # The cipher modes CBC, CFB, OFB and CTR all need an "initialization
  # vector", or short, IV. ECB mode is the only mode that does not require
  # an IV, but there is almost no legitimate use case for this mode
  # because of the fact that it does not sufficiently hide plaintext patterns.
  config :iv, :validate => :string

  def register
    require 'base64' if @base64
    # TODO : check if bad encryption fail the plugin
    @cipher = OpenSSL::Cipher.new(@algorithm)
    if @mode == "encrypt"
      @cipher.encrypt
    elsif @mode == "decrypt"
      @cipher.decrypt
    else
      @logger.error("Invalid cipher mode. Valid values are \"encrypt\" or \"decrypt\"", :mode => @mode)
      raise "Bad configuration, aborting."
    end

    if @key.length != @key_size
      @logger.debug("key length is " + @key.length.to_s + ", padding it to " + @key_size.to_s + " with '" + @key_pad.to_s + "'")
      @key = @key[0,32].ljust(32,@key_pad)
    end

    @cipher.key = @key

    @cipher.iv = @iv if @iv

    @cipher.padding = @cipher_padding if @cipher_padding

    #@logger.debug(:mode => @mode, :key => @key, :iv => @iv, :cipher_padding => @cipher_padding)

  end # def register

  def filter(event)
    return unless filter?(event)

    begin
      #@logger.debug("Event to filter", :event => event)
      data = event[@source]
      if @mode == "decrypt"
        data =  Base64.decode64(data) if @base64 == true
      end
      result = @cipher.update(data) + @cipher.final
      if @mode == "encrypt"
        data =  Base64.encode64(data) if @base64 == true
      end
    rescue => e
      @logger.warn("Exception catch on cipher filter", :event => event, :error => e)
    else
      event[@target]= result
      #Is it necessary to add 'if !result.nil?' ? exception have been already catched.
      filter_matched(event) if !result.nil?
    end
  end # def filter
end # class LogStash::Filters::Cipher
