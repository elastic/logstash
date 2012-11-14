require "logstash/filters/base"
require "logstash/namespace"

# This filter helps automatically parse messages which are of the 'foo=bar'
# variety.
#
# For example, if you have a log message which contains 'ip=1.2.3.4
# error=REFUSED', you can parse those automatically by doing:
# 
#   filter {
#     kv { }
#   }
#
# And you will get field 'ip' == "1.2.3.4" etc.
class LogStash::Filters::KV < LogStash::Filters::Base
  config_name "kv"
  plugin_status "beta"

  # The fields to perform 'key=value' searching on
  config :fields, :validate => :array, :default => ["@message"]

  # A string of characters to trim from the value. This is useful if your
  # values are wrapped in brackets or are terminated by comma (like postfix
  # logs)
  #
  # Example, to strip '<' '>' and ',' characters from values:
  # 
  #     filter { kv { trim => "<>," } }
  config :trim, :validate => :string


  # A string of characters to use as delimiters for parsing out key-value pairs.
  #
  # Example, to split out the args from a string such as
  # '?pin=12345~0&d=123&e=foo@bar.com&oq=bobo&ss=12345':
  # 
  #     filter { kv { field_split => "&?" } }
  config :field_split, :validate => :string, :default => ''


  # A string of characters to use as delimiters for identifying key-value relations.
  #
  # Example, to identify key-values such as
  # 'key1:value1 key2:value2':
  # 
  #     filter { kv { value_split => ":" } }
  config :value_split, :validate => :string, :default => '='

  # A string to prepend to all of the extracted keys
  #
  # Example, to prepend arg_ to all keys:
  #
  #     filter { kv { prefix => "arg_" } }
  config :prefix, :validate => :string, :default => ''

  # The name of the container to put all of the key-value pairs into 
  #
  # Example, to place all keys into container kv:
  #
  #     filter { kv { conatiner => "kv" } }
  config :container, :validate => :string

  def register
    @trim_re = Regexp.new("[#{@trim}]") if !@trim.nil?
    @value_split = @value_split
    @field_split = @field_split
    @prefix = @prefix
  end # def register

  def filter(event)
    return unless filter?(event)

    if !@container.nil?
      @kv_keys=Hash.new
    end
    @fields.each do |fieldname|
      value = event[fieldname]

      case value
        when String; parse(value, event)
        when Array; value.each { |v| parse(v, event) }
        else 
          @logger.warn("kv filter has no support for this type of data",
                       :type => value.type, :value => value)
      end # case value
    end
    if !@container.nil?
      # If we have any keys, create the hash
      if @kv_keys.length > 0
        event[@container] = @kv_keys
      end
    end
  end # def filter

  private
  def parse(text, event)
    if !event =~ /[@field_split]/
      return
    end
    scan_re = Regexp.new("([^ "+@field_split+@value_split+"]+)["+@value_split+"](?:\"([^\""+@field_split+"]+)\"|'([^'"+@field_split+"]+)'|([^ "+@field_split+"]+))")
    text.scan(scan_re) do |key, v1, v2, v3|
      value = v1 || v2 || v3
      if !@trim.nil?
        value = value.gsub(@trim_re, "")
      end
      key = @prefix + key
      if !@container.nil?
        @kv_keys[key] = value
      else
        event[key] = value
      end
    end
  end
end # class LogStash::Filter::KV
