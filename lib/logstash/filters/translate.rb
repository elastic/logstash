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


  # The field containing the words you wish to translate.
  # If this field is an array, only the first value will be used.
  config :field, :validate => :string, :required => true

  # The destination you wish to populate with the translated text..    
  # default is `translation`.  set to the same value as source
  # if you want to do a substitution.
  config :destination, :validate => :string, :default => "translation"

  # name with full path of external dictionary file.    
  # format of the table should be a YAML file. 
  # make sure you encase any integer based keys in quotes.
  # if not specified will use embedded @dictionary below.
  config :dictionary, :validate => :string

  # set to false if you want to match multiple terms.   
  # a large dictionary could get expensive if set to false.
  config :exact, :validate => :boolean, :default => true



  public
  def register
    if @dictionary.nil?
      @dictionary = 
      { 
        "100" => "continue",  "101" => "switching_protocols",  "102" => "processing",  "200" => "ok",  "201" => "created",  "202" => "accepted",  
        "203" => "non_authoritative_information",  "204" => "no_content",  "205" => "reset_content",  "206" => "partial_content",  "207" => "multi_status",  
        "226" => "im_used",  "300" => "multiple_choices",  "301" => "moved_permanently",  "302" => "found",  "303" => "see_other",  "304" => "not_modified",  
        "305" => "use_proxy",  "307" => "temporary_redirect",  "400" => "bad_request",  "401" => "unauthorized",  "402" => "payment_required",  
        "403" => "forbidden",  "404" => "not_found",  "405" => "method_not_allowed",  "406" => "not_acceptable",  "407" => "proxy_authentication_required",  
        "408" => "request_timeout",  "409" => "conflict",  "410" => "gone",  "411" => "length_required",  "412" => "precondition_failed",  
        "413" => "request_entity_too_large",  "414" => "request_uri_too_long",  "415" => "unsupported_media_type",  "416" => "requested_range_not_satisfiable",  
        "417" => "expectation_failed",  "422" => "unprocessable_entity",  "423" => "locked",  "424" => "failed_dependency",  "426" => "upgrade_required",  
        "500" => "internal_server_error",  "501" => "not_implemented",  "502" => "bad_gateway",  "503" => "service_unavailable",  "504" => "gateway_timeout",  
        "505" => "http_version_not_supported",  "507" => "insufficient_storage",  "510" => "not_extended" 
      }
    else 
      if File.exists?(@dictionary)
        begin
          @dictionary = YAML.load_file(@dictionary)
        rescue Exception => e
          raise "Bad Syntax in dictionary file" 
        end
      end # if File.exists?
    end # if @dictionary.nil?
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
          translation = @dictionary[source] if defined? @dictionary[source]
        else 
          translation = source.gsub(Regexp.union(@dictionary.keys), @dictionary)
        end # if @exact
      rescue Exception => e
          @logger.error("Something went wrong when attempting to translate from dictionary", :exception => e, :field => @field, :event => event)
      end
      event[@destination] = translation
  end # def filter
end # class LogStash::Filters::Translate
