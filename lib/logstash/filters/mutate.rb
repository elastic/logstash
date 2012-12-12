require "logstash/filters/base"
require "logstash/namespace"
require "logstash/time"

# The mutate filter allows you to do general mutations to fields. You
# can rename, remove, replace, and modify fields in your events.
#
# TODO(sissel): Support regexp replacements like String#gsub ?
class LogStash::Filters::Mutate < LogStash::Filters::Base
  config_name "mutate"
  plugin_status "stable"

  # Rename one or more fields.
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #         # Renames the 'HOSTORIP' field to 'client_ip'
  #         rename => [ "HOSTORIP", "client_ip" ]
  #       }
  #     }
  config :rename, :validate => :hash

  # Remove one or more fields.
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #         remove => [ "client" ]  # Removes the 'client' field
  #       }
  #     }
  config :remove, :validate => :array

  # Replace a field with a new value. The new value can include %{foo} strings
  # to help you build a new value from other parts of the event.
  #
  # Example:
  # 
  #     filter {
  #       mutate {
  #         replace => [ "@message", "%{source_host}: My new message" ]
  #       }
  #     }
  config :replace, :validate => :hash

  # Convert a field's value to a different type, like turning a string to an
  # integer. If the field value is an array, all members will be converted.
  # If the field is a hash, no action will be taken.
  #
  # Valid conversion targets are: integer, float, string
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #         convert => [ "fieldname", "integer" ]
  #       }
  #     }
  config :convert, :validate => :hash

  # Convert a string field by applying a regular expression and a replacement
  # if the field is not a string, no action will be taken
  # 
  # this configuration takes an array consisting of 3 elements per field/substitution
  #
  # be aware of escaping any backslash in the config file
  #
  # for example:
  #
  #    mutate {
  #      gsub => [
  #        # replace all forward slashes with underscore
  #        "fieldname", "\\/", "_",
  #        # replace backslashes, question marks, hashes and minuses with underscore
  #        "fieldname", "[\\?#-]", "_"
  #      ]
  #    }
  #
  config :gsub, :validate => :array

  # Convert a string to its uppercase equivalent
  # 
  # Example:
  # 
  #    mutate {
  #      uppercase => [ "fieldname" ]
  #    }
  # 
  config :uppercase, :validate => :array
  
  # Convert a string to its lowercase equivalent
  # 
  # Example:
  # 
  #   mutate {
  #     lowercase => [ "fieldname" ]
  #   }
  # 
  config :lowercase, :validate => :array

  public
  def register
    valid_conversions = %w(string integer float)
    # TODO(sissel): Validate conversion requests if provided.
    @convert.nil? or @convert.each do |field, type|
      if !valid_conversions.include?(type)
        @logger.error("Invalid conversion type",
                      "type" => type, "expected one of" => valid_types)
        # TODO(sissel): It's 2011, man, let's actually make like.. a proper
        # 'configuration broken' exception
        raise "Bad configuration, aborting."
      end
    end # @convert.each
    
    @gsub_parsed = []
    @gsub.nil? or @gsub.each_slice(3) do |field, needle, replacement|
      if [field, needle, replacement].any? {|n| n.nil?}
        @logger.error("Invalid gsub configuration. gsub has to define 3 elements per config entry", :field => field, :needle => needle, :replacement => replacement)
        raise "Bad configuration, aborting."
      end
      @gsub_parsed << {
        :field        => field,
        :needle       => Regexp.new(needle),
        :replacement  => replacement
      }
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    rename(event) if @rename
    replace(event) if @replace
    convert(event) if @convert
    gsub(event) if @gsub
    uppercase(event) if @uppercase
    lowercase(event) if @lowercase
    remove(event) if @remove

    filter_matched(event)
  end # def filter

  private
  def remove(event)
    # TODO(sissel): use event.sprintf on the field names?
    @remove.each do |field|
      event.remove(field)
    end
  end # def remove

  private
  def rename(event)
    # TODO(sissel): use event.sprintf on the field names?
    @rename.each do |old, new|
      next unless event.include?(old)
      event[new] = event.remove(old)
    end
  end # def rename

  private
  def replace(event)
    # TODO(sissel): use event.sprintf on the field names?
    @replace.each do |field, newvalue|
      event[field] = event.sprintf(newvalue)
    end
  end # def replace

  def convert(event)
    @convert.each do |field, type|
      original = event[field]

      # calls convert_{string,integer,float} depending on type requested.
      converter = method("convert_" + type)
      if original.is_a?(Hash)
        @logger.debug("I don't know how to type convert a hash, skipping",
                      :field => field, :value => original)
        next
      elsif original.is_a?(Array)
        value = original.map { |v| converter.call(v) }
      else
        value = converter.call(original)
      end
      event[field] = value
    end
  end # def convert

  def convert_string(value)
    return value.to_s
  end # def convert_string

  def convert_integer(value)
    return value.to_i
  end # def convert_integer

  def convert_float(value)
    return value.to_f
  end # def convert_float

  private
  def gsub(event)
    @gsub_parsed.each do |config|
      field = config[:field]
      needle = config[:needle]
      replacement = config[:replacement]

      if event[field].is_a?(Array)
        event[field] = event[field].map do |v|
          if not v.is_a?(String)
            @logger.warn("gsub mutation is only applicable for Strings, " +
                          "skipping", :field => field, :value => v)
            v
          else
            v.gsub(needle, replacement)
          end
        end
      else
        if not event[field].is_a?(String)
          @logger.debug("gsub mutation is only applicable for Strings, " +
                        "skipping", :field => field, :value => event[field])
          next
        end
        event[field] = event[field].gsub(needle, replacement)
      end
    end # @gsub_parsed.each
  end # def gsub
  
  private
  def uppercase(event)
    @uppercase.each do |field|
      if event[field].is_a?(Array)
        event[field].each { |v| v.upcase! }
      elsif event[field].is_a?(String)
        event[field].upcase!
      else
        @logger.debug("Can't uppercase something that isn't a string",
                      :field => field, :value => event[field])
      end
    end
  end # def uppercase

  private
  def lowercase(event)
    @lowercase.each do |field|
      if event[field].is_a?(Array)
        event[field].each { |v| v.downcase! }
      elsif event[field].is_a?(String)
        event[field].downcase!
      else
        @logger.debug("Can't lowercase something that isn't a string",
                      :field => field, :value => event[field])
      end
    end
  end # def lowercase
end # class LogStash::Filters::Mutate
