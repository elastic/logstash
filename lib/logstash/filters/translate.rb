require "logstash/filters/base"
require "logstash/namespace"

# Originally written to translate HTTP response codes 
# but turned into a general translation tool which uses
# .yaml files as a dictionary.
# response codes in default dictionary were scraped from 
# 'gem install cheat; cheat status_codes'

class LogStash::Filters::Translate < LogStash::Filters::Base
  config_name "translate"
  plugin_status "experimental"


  # The field containing a response code If this field is an
  # array, only the first value will be used.
  config :field, :validate => :string, :required => true

  # name with full path of external dictionary file.    
  # format of the table should be a YAML file. 
  # make sure you encase any integer based keys in quotes.
  # For simple string search and replacements for just a few values
  # use the gsub function of the mutate filter.
  config :dictionary_path, :validate => :string, :required => true

  # The destination you wish to populate with the response code.    
  # default is http_response_code.  set to the same value as source
  # if you want to do a substitution.
  config :destination, :validate => :string, :default => "translation"

  # set to false if you want to match multiple terms.   
  # a large dictionary could get expensive if set to false.
  config :exact, :validate => :boolean, :default => true



  public
  def register
    if File.exists?(@dictionary_path)
      begin
        @dictionary = YAML.load_file(@dictionary_path)
      rescue Exception => e
        raise "Bad Syntax in dictionary file" 
      end
    end # if File.exists?
    @logger.info("Dictionary - ", :dictionary => @dictionary)
    if @exact
      @logger.info("Dictionary translation method - Exact")
    else 
      @logger.info("Dictionary translation method - Fuzzy")
    end # if @exact
  end # def register

  public
  def filter(event)
    return unless filter?(event)
      begin
        source = event[@field]
        source = source.first if source.is_a? Array # if array,  just use first value 
        source = source.to_s # make sure its a string.  Is this really needed?
        if @exact
          translation = @dictionary[source] if @dictionary.include?(source)
        else 
          translation = source.gsub(Regexp.union(@dictionary.keys), @dictionary)
        end # if @exact
      rescue Exception => e
          @logger.error("Something went wrong when attempting to translate from dictionary", :exception => e, :field => @field, :event => event)
      end
      event[@destination] = translation
  end # def filter
end # class LogStash::Filters::Translate
