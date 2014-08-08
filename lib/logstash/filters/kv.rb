# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# This filter helps automatically parse messages (or specific event fields)
# which are of the 'foo=bar' variety.
#
# For example, if you have a log message which contains 'ip=1.2.3.4
# error=REFUSED', you can parse those automatically by configuring:
#
#     filter {
#       kv { }
#     }
#
# The above will result in a message of "ip=1.2.3.4 error=REFUSED" having
# the fields:
#
# * ip: 1.2.3.4
# * error: REFUSED
#
# This is great for postfix, iptables, and other types of logs that
# tend towards 'key=value' syntax.
#
# You can configure any arbitrary strings to split your data on,
# in case your data is not structured using '=' signs and whitespace.
# For example, this filter can also be used to parse query parameters like
# 'foo=bar&baz=fizz' by setting the `field_split` parameter to "&".
class LogStash::Filters::KV < LogStash::Filters::Base
  config_name "kv"
  milestone 2

  # A string of characters to trim from the value. This is useful if your
  # values are wrapped in brackets or are terminated with commas (like postfix
  # logs).
  #
  # These characters form a regex character class and thus you must escape special regex
  # characters like '[' or ']' using '\'.
  #
  # For example, to strip '<', '>', '[', ']' and ',' characters from values:
  #
  #     filter {
  #       kv {
  #         trim => "<>\[\],"
  #       }
  #     }
  config :trim, :validate => :string

  # A string of characters to trim from the key. This is useful if your
  # keys are wrapped in brackets or start with space.
  #
  # These characters form a regex character class and thus you must escape special regex
  # characters like '[' or ']' using '\'.
  #
  # For example, to strip '<' '>' '[' ']' and ',' characters from keys:
  #
  #     filter {
  #       kv {
  #         trimkey => "<>\[\],"
  #       }
  #     }
  config :trimkey, :validate => :string

  # A string of characters to use as delimiters for parsing out key-value pairs.
  #
  # These characters form a regex character class and thus you must escape special regex
  # characters like '[' or ']' using '\'.
  #
  # #### Example with URL Query Strings
  #
  # For example, to split out the args from a url query string such as
  # '?pin=12345~0&d=123&e=foo@bar.com&oq=bobo&ss=12345':
  #
  #     filter {
  #       kv {
  #         field_split => "&?"
  #       }
  #     }
  #
  # The above splits on both "&" and "?" characters, giving you the following
  # fields:
  #
  # * pin: 12345~0
  # * d: 123
  # * e: foo@bar.com
  # * oq: bobo
  # * ss: 12345
  config :field_split, :validate => :string, :default => ' '


  # A string of characters to use as delimiters for identifying key-value relations.
  #
  # These characters form a regex character class and thus you must escape special regex
  # characters like '[' or ']' using '\'.
  #
  # For example, to identify key-values such as
  # 'key1:value1 key2:value2':
  #
  #     filter { kv { value_split => ":" } }
  config :value_split, :validate => :string, :default => '='

  # A string to prepend to all of the extracted keys.
  #
  # For example, to prepend arg_ to all keys:
  #
  #     filter { kv { prefix => "arg_" } }
  config :prefix, :validate => :string, :default => ''

  # The field to perform 'key=value' searching on
  #
  # For example, to process the `not_the_message` field:
  #
  #     filter { kv { source => "not_the_message" } }
  config :source, :validate => :string, :default => "message"

  # The name of the container to put all of the key-value pairs into.
  #
  # If this setting is omitted, fields will be written to the root of the
  # event, as individual fields.
  #
  # For example, to place all keys into the event field kv:
  #
  #     filter { kv { target => "kv" } }
  config :target, :validate => :string

  # An array specifying the parsed keys which should be added to the event.
  # By default all keys will be added.
  #
  # For example, consider a source like "Hey, from=<abc>, to=def foo=bar". 
  # To include "from" and "to", but exclude the "foo" key, you could use this configuration:
  #     filter {
  #       kv {
  #         include_keys => [ "from", "to" ]
  #       }
  #     }
  config :include_keys, :validate => :array, :default => []

  # An array specifying the parsed keys which should not be added to the event.
  # By default no keys will be excluded.
  #
  # For example, consider a source like "Hey, from=<abc>, to=def foo=bar". 
  # To exclude "from" and "to", but retain the "foo" key, you could use this configuration:
  #     filter {
  #       kv {
  #         exclude_keys => [ "from", "to" ]
  #       }
  #     }
  config :exclude_keys, :validate => :array, :default => []

  # A hash specifying the default keys and their values which should be added to the event
  # in case these keys do not exist in the source field being parsed.
  #
  #     filter {
  #       kv {
  #         default_keys => [ "from", "logstash@example.com",
  #                          "to", "default@dev.null" ]
  #       }
  #     }
  config :default_keys, :validate => :hash, :default => {}

  def register
    @trim_re = Regexp.new("[#{@trim}]") if !@trim.nil?
    @trimkey_re = Regexp.new("[#{@trimkey}]") if !@trimkey.nil?
    @scan_re = Regexp.new("((?:\\\\ |[^"+@field_split+@value_split+"])+)["+@value_split+"](?:\"([^\"]+)\"|'([^']+)'|((?:\\\\ |[^"+@field_split+"])+))")
  end # def register

  def filter(event)
    return unless filter?(event)

    kv = Hash.new

    value = event[@source]

    case value
      when nil; # Nothing to do
      when String; kv = parse(value, event, kv)
      when Array; value.each { |v| kv = parse(v, event, kv) }
      else
        @logger.warn("kv filter has no support for this type of data",
                     :type => value.class, :value => value)
    end # case value

    # Add default key-values for missing keys
    kv = @default_keys.merge(kv)

    # If we have any keys, create/append the hash
    if kv.length > 0
      if @target.nil?
        # Default is to write to the root of the event.
        dest = event.to_hash
      else
        if !event[@target].is_a?(Hash)
          @logger.debug("Overwriting existing target field", :target => @target)
          dest = event[@target] = {}
        else
          dest = event[@target]
        end
      end

      dest.merge!(kv)
      filter_matched(event)
    end
  end # def filter

  private
  def parse(text, event, kv_keys)
    if !event =~ /[@field_split]/
      return kv_keys
    end
    
    # Interpret dynamic keys for @include_keys and @exclude_keys
    include_keys = @include_keys.map{|key| event.sprintf(key)}
    exclude_keys = @exclude_keys.map{|key| event.sprintf(key)}
    
    text.scan(@scan_re) do |key, v1, v2, v3|
      value = v1 || v2 || v3
      key = @trimkey.nil? ? key : key.gsub(@trimkey_re, "")
      
      # Bail out as per the values of include_keys and exclude_keys
      next if not include_keys.empty? and not include_keys.include?(key)
      next if exclude_keys.include?(key)

      key = event.sprintf(@prefix) + key

      value = @trim.nil? ? value : value.gsub(@trim_re, "")
      if kv_keys.has_key?(key)
        if kv_keys[key].is_a? Array
          kv_keys[key].push(value)
        else
          kv_keys[key] = [kv_keys[key], value]
        end
      else
        kv_keys[key] = value
      end
    end
    return kv_keys
  end
end # class LogStash::Filters::KV
