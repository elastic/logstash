require "logstash/filters/base"
require "logstash/namespace"

# Regexp filter. Match and capture results as fields.
#
# The primary purpose of this filter is to match a given field with a regexp
# and use that match to add new fields based on the match.
#
# This filter should work but is not yet finalized. It is likely to be
# merged with the grok filter.
#
# Example:
#
#    filter {
#      regexp {
#        match => [ "@message", "\b([0-9]+)\b" ]
#        add_field => [ "number", "\1" ]
#      }
#    }
#
# If the message is "hello 123 world", then the above filter configuration will
# add a field "number" with "123" in it.
#     
class LogStash::Filters::Regexp < LogStash::Filters::Base

  config_name "regexp"

  # A hash of matches of field => value
  config :match, :validate => :hash, :default => {}

  # Any existing field name can be used as a config name here for matching
  # against.
  #     
  #     # this config:
  #     foo => "some pattern"
  #
  #     # same as:
  #     match => [ "foo", "some pattern" ]
  config /[A-Za-z0-9_-]+/, :validate => :string

  public
  def register
    @patterns = Hash.new { |h,k| h[k] = [] }
    @match.merge(@config).each do |field, pattern|
      # Skip known config names
      next if ["add_tag", "add_field", "type", "negate", "match"].include?(field)
      @logger.info(field => pattern)

      re = Regexp.new(pattern)
      @patterns[field] << re
      @logger.debug(["regexp: #{@type}/#{field}", pattern, re])
    end # @config.each

    if @add_field.empty?
      raise "add_field was not specified for regexp filter" 
    end
  end # def register

  public
  def filter(event)
    if event.type != @type
      @logger.debug("regexp: skipping type #{event.type} from #{event.source}")
      return
    end

    @logger.debug(["Running regexp filter", event.to_hash, config])

    @patterns.each do |field, regexes|
      if !event[field]
        @logger.debug(["Skipping match object, field not present", field,
                      event, event[field]])
        next
      end

      regexes.each do |re|
        (event[field].is_a?(Array) ? event[field] : [event[field]]).each do |value|
          match = re.match(value)
          next unless match
          @logger.debug("Field '#{field}' matched #{re}")

          # TODO(sissel): support type coercion (int, float, etc)
          @add_field.each do |name, addvalue|
            # Replace any \1 (etc) with that capture group
            @logger.debug("Adding #{name} => #{addvalue}")
            @logger.debug("Match: #{match.inspect}")
            addvalue.gsub!(/\\[0-9]+/) { |i| 
              @logger.debug("#{i.inspect} => #{match[i[1..-1].to_i]}")
              match[i[1..-1].to_i] or i rescue i 
            }
            @logger.debug("filters/#{self.class.name}: adding #{addvalue} to field #{field}")
            event[name] ||= []
            event[name] << event.sprintf(addvalue)
          end
        end
      end # regexes.each
    end # patterns.each
  end # def filter
end # class LogStash::Filters::Grep
