# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# The mutate filter allows you to perform general mutations on fields. You
# can rename, remove, replace, and modify fields in your events.
#
# TODO(sissel): Support regexp replacements like String#gsub ?
class LogStash::Filters::Mutate < LogStash::Filters::Base
  config_name "mutate"
  milestone 3

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
  #
  # This option is deprecated, instead use remove_field option available in all
  # filters.
  config :remove, :validate => :array, :deprecated => true

  # Replace a field with a new value. The new value can include %{foo} strings
  # to help you build a new value from other parts of the event.
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #         replace => [ "message", "%{source_host}: My new message" ]
  #       }
  #     }
  config :replace, :validate => :hash

  # Update an existing field with a new value. If the field does not exist,
  # then no action will be taken.
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #         update => [ "sample", "My new message" ]
  #       }
  #     }
  config :update, :validate => :hash

  # Convert a field's value to a different type, like turning a string to an
  # integer. If the field value is an array, all members will be converted.
  # If the field is a hash, no action will be taken.
  #
  # Valid conversion targets are: integer, float, string.
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #         convert => [ "fieldname", "integer" ]
  #       }
  #     }
  config :convert, :validate => :hash

  # Convert a string field by applying a regular expression and a replacement.
  # If the field is not a string, no action will be taken.
  #
  # This configuration takes an array consisting of 3 elements per
  # field/substitution.
  #
  # Be aware of escaping any backslash in the config file.
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #         gsub => [
  #           # replace all forward slashes with underscore
  #           "fieldname", "/", "_",
  #
  #           # replace backslashes, question marks, hashes, and minuses with
  #           # dot
  #           "fieldname2", "[\\?#-]", "."
  #         ]
  #       }
  #     }
  #
  config :gsub, :validate => :array

  # Convert a string to its uppercase equivalent.
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #         uppercase => [ "fieldname" ]
  #       }
  #     }
  config :uppercase, :validate => :array

  # Convert a string to its lowercase equivalent.
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #         lowercase => [ "fieldname" ]
  #       }
  #     }
  config :lowercase, :validate => :array

  # Split a field to an array using a separator character. Only works on string
  # fields.
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #          split => ["fieldname", ","]
  #       }
  #     }
  config :split, :validate => :hash

  # Join an array with a separator character. Does nothing on non-array fields.
  #
  # Example:
  #
  #    filter {
  #      mutate {
  #        join => ["fieldname", ","]
  #      }
  #    }
  config :join, :validate => :hash

  # Strip whitespace from field. NOTE: this only works on leading and trailing whitespace.
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #          strip => ["field1", "field2"]
  #       }
  #     }
  config :strip, :validate => :array

  # Merge two fields of arrays or hashes.
  # String fields will be automatically be converted into an array, so:
  #   array + string will work
  #   string + string will result in an 2 entry array in dest_field
  #   array and hash will not work
  #
  # Example:
  #
  #     filter {
  #       mutate {
  #          merge => ["dest_field", "added_field"]
  #       }
  #     }
  config :merge, :validate => :hash

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
    update(event) if @update
    replace(event) if @replace
    convert(event) if @convert
    gsub(event) if @gsub
    uppercase(event) if @uppercase
    lowercase(event) if @lowercase
    strip(event) if @strip
    remove(event) if @remove
    split(event) if @split
    join(event) if @join
    merge(event) if @merge

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
  def update(event)
    @update.each do |field, newvalue|
      next unless event.include?(field)
      event[field] = event.sprintf(newvalue)
    end
  end # def update

  private
  def replace(event)
    @replace.each do |field, newvalue|
      event[field] = event.sprintf(newvalue)
    end
  end # def replace

  def convert(event)
    @convert.each do |field, type|
      next unless event.include?(field)
      original = event[field]

      # calls convert_{string,integer,float} depending on type requested.
      converter = method("convert_" + type)
      if original.nil?
        next
      elsif original.is_a?(Hash)
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
    # since this is a filter and all inputs should be already UTF-8
    # we wont check valid_encoding? but just force UTF-8 for
    # the Fixnum#to_s case which always result in US-ASCII
    # see https://twitter.com/jordansissel/status/444613207143903232
    return value.to_s.force_encoding(Encoding::UTF_8)
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

  private
  def split(event)
    @split.each do |field, separator|
      if event[field].is_a?(String)
        event[field] = event[field].split(separator)
      else
        @logger.debug("Can't split something that isn't a string",
                      :field => field, :value => event[field])
      end
    end
  end

  private
  def join(event)
    @join.each do |field, separator|
      if event[field].is_a?(Array)
        event[field] = event[field].join(separator)
      end
    end
  end

  private
  def strip(event)
    @strip.each do |field|
      if event[field].is_a?(Array)
        event[field] = event[field].map{|s| s.strip }
      elsif event[field].is_a?(String)
        event[field] = event[field].strip
      end
    end
  end

  private
  def merge(event)
    @merge.each do |dest_field, added_fields|
      #When multiple calls, added_field is an array
      added_fields = [ added_fields ] if ! added_fields.is_a?(Array)
      added_fields.each do |added_field|
        if event[dest_field].is_a?(Hash) ^ event[added_field].is_a?(Hash)
          @logger.error("Not possible to merge an array and a hash: ",
                        :dest_field => dest_field,
                        :added_field => added_field )
          next
        end
        if event[dest_field].is_a?(Hash) #No need to test the other
          event[dest_field].update(event[added_field])
        else
          event[dest_field] = [event[dest_field]] if ! event[dest_field].is_a?(Array)
          event[added_field] = [event[added_field]] if ! event[added_field].is_a?(Array)
         event[dest_field].concat(event[added_field])
        end
      end
    end
  end

end # class LogStash::Filters::Mutate
