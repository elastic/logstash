require "logstash/filters/base"
require "logstash/namespace"

# Originally written to translate HTTP response codes 
# but turned into a general translation tool which uses
# configured has or/and .yaml files as a dictionary.
# response codes in default dictionary were scraped from 
# 'gem install cheat; cheat status_codes'
#
# Alternatively for simple string search and replacements for just a few values
# use the gsub function of the mutate filter.

class LogStash::Filters::Translate < LogStash::Filters::Base
  config_name "translate"
  plugin_status "experimental"

  # The field containing a response code If this field is an
  # array, only the first value will be used.
  config :field, :validate => :string, :required => true

  # In case dstination field already exists should we skip translation(default) or override it with new translation
  config :override, :validate => :boolean, :default => false

  # Dictionary to use for translation.
  # Example:
  #
  #     filter {
  #       %PLUGIN% {
  #         dictionary => [ "100", "Continue",
  #                         "101", "Switching Protocols",
  #                         "200", "OK",
  #                         "201", "Created",
  #                         "202", "Accepted" ]
  #       }
  #     }
  config :dictionary, :validate => :hash,  :default => {}

  # name with full path of external dictionary file.    
  # format of the table should be a YAML file which will be merged with the @dictionary.
  # make sure you encase any integer based keys in quotes.
  config :dictionary_path, :validate => :path

  # The destination field you wish to populate with the translation code.
  # default is "translation".
  # Set to the same value as source if you want to do a substitution, in this case filter will allways succeed.
  config :destination, :validate => :string, :default => "translation"

  # set to false if you want to match multiple terms
  # a large dictionary could get expensive if set to false.
  config :exact, :validate => :boolean, :default => true

  # treat dictionary keys as regular expressions to match against, used only then @exact enabled.
  config :regex, :validate => :boolean, :default => false

  # Incase no translation was made add default translation string
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
