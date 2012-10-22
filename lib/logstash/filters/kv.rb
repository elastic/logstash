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

  def register
    @trim_re = Regexp.new("[#{@trim}]") if !@trim.nil?
  end # def register

  def filter(event)
    return unless filter?(event)

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
  end # def filter

  private
  def parse(text, event)
    #text.scan(/([^ =]+)=("[^"]+"|'[^']+'|[^ ]+)/) do |key, value|
    text.scan(/([^ =]+)=(?:"([^"]+)"|'([^']+)'|([^ ]+))/) do |key, v1, v2, v3|
      value = v1 || v2 || v3
      if !@trim.nil?
        value = value.gsub(@trim_re, "")
      end

      event[key] = value
    end
  end
end # class LogStash::Filter::KV
