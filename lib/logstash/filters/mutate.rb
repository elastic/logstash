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
  # the pattern and the replacement have to be seperated by / the slash can be escaped with a backslash \
  #
  # be aware of escaping the backslash in the config file
  #
  # for example:
  #
  #    mutate {
  #       …
  #      gsub => [
  #        "fieldname", "\\//_",      #replace all forward slashes with underscore
  #        "fieldname", "[\\?#-]/_"   #replace backslashes, question marks, hashes and minuses with underscore
  #      ]
  #       …
  #    }
  #
  config :gsub, :validate => :hash

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
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    rename(event) if @rename
    remove(event) if @remove
    replace(event) if @replace
    convert(event) if @convert
    gsub(event) if @gsub

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
      event[new] = event[old]
      event.remove(old)
    end
  end # def rename

  private
  def replace(event)
    # TODO(sissel): use event.sprintf on the field names?
    @replace.each do |field, newvalue|
      next unless event[field]
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
    @gsub.each do |field, replacement_string|
      match = replacement_string.split(/(?!<[\/])\//, 2)
      if match == nil
        @logger.debug("gsub mutation requires a / separated pattern/replacement pair, skipping",
                      :field => field, :value => event[field])
        next
      end
      if(event[field].is_a?(Array))
        event[field] = event[field].map do |v| 
          if not v.is_a?(String)
            @logger.debug("gsub mutation is only applicable for Strings, skipping",
                          :field => field, :value => event[field])
            next
          end
          v.gsub(Regexp.new(match[0]), match[1]) 
        end
      else
        if not event[field].is_a?(String)
          @logger.debug("gsub mutation is only applicable for Strings, skipping",
                        :field => field, :value => event[field])
          next
        end
        event[field] = event[field].gsub(Regexp.new(match[0]), match[1])
      end
    end # @gsub.each
  end # def gsub
end # class LogStash::Filters::Mutate
