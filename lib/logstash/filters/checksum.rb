# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "yaml"

# This filter let's you create a checksum based on various parts
# of the logstash event.
# This can be useful for deduplication of messages or simply to provide
# a custom unique identifier.
#
# This is VERY experimental and is largely a proof-of-concept
class LogStash::Filters::Checksum < LogStash::Filters::Base

  config_name "checksum"
  milestone 1

  ALGORITHMS = ["md5", "sha", "sha1", "sha256", "sha384",]

  # A list of keys to use in creating the string to checksum
  # Keys will be sorted before building the string
  # keys and values will then be concatenated with pipe delimeters
  # and checksummed
  config :keys, :validate => :array, :default => ["message", "@timestamp", "type"]

  config :algorithm, :validate => ALGORITHMS, :default => "sha256"

  public
  def register
    require 'openssl'
    @to_checksum = ""
  end

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running checksum filter", :event => event)

    @keys.sort.each do |k|
      @logger.debug("Adding key to string", :current_key => k)
      @to_checksum << "|#{k}|#{event[k]}"
    end
    @to_checksum << "|"
    @logger.debug("Final string built", :to_checksum => @to_checksum)


    # in JRuby 1.7.11 outputs as ASCII-8BIT
    digested_string = OpenSSL::Digest.hexdigest(@algorithm, @to_checksum).force_encoding(Encoding::UTF_8)

    @logger.debug("Digested string", :digested_string => digested_string)
    event['logstash_checksum'] = digested_string
  end
end # class LogStash::Filters::Checksum
