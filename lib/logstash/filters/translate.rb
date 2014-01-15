# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# A general search and replace tool which uses a configured hash
# and/or a YAML file to determine replacement values.
#
# The dictionary entries can be specified in one of two ways: First,
# the "dictionary" configuration item may contain a hash representing
# the mapping. Second, an external YAML file (readable by logstash) may be specified
# in the "dictionary_path" configuration item. These two methods may not be used
# in conjunction; it will produce an error.
#
# Operationally, if the event field specified in the "field" configuration
# matches the EXACT contents of a dictionary entry key (or matches a regex if
# "regex" configuration item has been enabled), the field's value will be substituted
# with the matched key's value from the dictionary.
#
# By default, the translate filter will replace the contents of the 
# maching event field (in-place). However, by using the "destination"
# configuration item, you may also specify a target event field to
# populate with the new translated value.
# 
# Alternatively, for simple string search and replacements for just a few values
# you might consider using the gsub function of the mutate filter.

class LogStash::Filters::Translate < LogStash::Filters::Base
  config_name "translate"
  milestone 1

  # The name of the logstash event field containing the value to be compared for a
  # match by the translate filter (e.g. "message", "host", "response_code"). 
  # 
  # If this field is an array, only the first value will be used.
  config :field, :validate => :string, :required => true

  # If the destination (or target) field already exists, this configuration item specifies
  # whether the filter should skip translation (default) or overwrite the target field
  # value with the new translation value.
  config :override, :validate => :boolean, :default => false

  # The dictionary to use for translation, when specified in the logstash filter
  # configuration item (i.e. do not use the @dictionary_path YAML file)
  # Example:
  #
  #     filter {
  #       %PLUGIN% {
  #         dictionary => [ "100", "Continue",
  #                         "101", "Switching Protocols",
  #                         "merci", "thank you",
  #                         "old version", "new version" ]
  #       }
  #     }
  # NOTE: it is an error to specify both @dictionary and @dictionary_path
  config :dictionary, :validate => :hash,  :default => {}

  # The full path of the external YAML dictionary file. The format of the table
  # should be a standard YAML file which will be merged with the @dictionary. Make
  # sure you specify any integer-based keys in quotes. The YAML file should look
  # something like this:
  #
  #     "100": Continue
  #     "101": Switching Protocols
  #     merci: gracias
  #     old version: new version
  #     
  # NOTE: it is an error to specify both @dictionary and @dictionary_path
  config :dictionary_path, :validate => :path

  # The destination field you wish to populate with the translated code. The default
  # is a field named "translation". Set this to the same value as source if you want
  # to do a substitution, in this case filter will allways succeed. This will clobber
  # the old value of the source field! 
  config :destination, :validate => :string, :default => "translation"

  # Set to false if you want to match multiple terms. A large dictionary could get expensive if set to false.
  config :exact, :validate => :boolean, :default => true

  # Set this to true (default is false), if you'd like to treat dictionary keys as
  # regular expressions to match against, this is used only when the "exact" configuration
  # is enabled (true).
  config :regex, :validate => :boolean, :default => false

  # In case no translation occurred in the event, this will add a default translation
  # string, which will always populate "field", regardless of whether the translate
  # filter matched.
  config :fallback, :validate => :string

  public
  def register
    if @dictionary_path
      raise "#{self.class.name}: dictionary file #{@dictionary_path} does not exists" unless File.exists?(@dictionary_path)
      begin
        @dictionary.merge!(YAML.load_file(@dictionary_path))
      rescue Exception => e
        raise "#{self.class.name}: Bad Syntax in dictionary file #{@dictionary_path}"
      end
    end
    
    @logger.debug? and @logger.debug("#{self.class.name}: Dictionary - ", :dictionary => @dictionary)
    if @exact
      @logger.debug? and @logger.debug("#{self.class.name}: Dictionary translation method - Exact")
    else
      @logger.debug? and @logger.debug("#{self.class.name}: Dictionary translation method - Fuzzy")
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    return unless event.include?(@field) # Skip translation in case event does not have @event field.
    return if event.include?(@destination) and not @override # Skip translation in case @destination field already exists and @override is disabled.

    begin
      #If source field is array use first value and make sure source value is string
      source = event[@field].is_a?(Array) ? event[@field].first.to_s : event[@field].to_s
      matched = false
      if @exact
        if @regex
          key = @dictionary.keys.detect{|k| source.match(Regexp.new(k))}
          if key
            event[@destination] = @dictionary[key]
            matched = true
          end
        elsif @dictionary.include?(source)
          event[@destination] = @dictionary[source]
          matched = true
        end
      else 
        translation = source.gsub(Regexp.union(@dictionary.keys), @dictionary)
        if source != translation
          event[@destination] = translation
          matched = true
        end
      end

      if not matched and @fallback
        event[@destination] = @fallback
        matched = true
      end
      filter_matched(event) if matched or @field == @destination
    rescue Exception => e
      @logger.error("Something went wrong when attempting to translate from dictionary", :exception => e, :field => @field, :event => event)
    end
  end # def filter
end # class LogStash::Filters::Translate
