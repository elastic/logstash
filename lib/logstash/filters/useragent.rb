require "logstash/filters/base"
require "logstash/namespace"
require "tempfile"

# Parse user agent strings into structured data based on BrowserScope data
#
# UserAgent filter, adds information about user agent like family, operating
# system, version, and device
#
# Logstash releases ship with the regexes.yaml database made available from
# ua-parser with an Apache 2.0 license. For more details on ua-parser, see
# <https://github.com/tobie/ua-parser/>.
class LogStash::Filters::UserAgent < LogStash::Filters::Base
  config_name "useragent"
  milestone 1

  # The field containing the user agent string. If this field is an
  # array, only the first value will be used.
  config :source, :validate => :string, :required => true

  # The name of the field to assign user agent data into.
  #
  # If not specified user agent data will be stored in the root of the event.
  config :target, :validate => :string

  # regexes.yaml file to use
  #
  # If not specified, this will default to the regexes.yaml that ships
  # with logstash.
  #
  # You can find the latest version of this here:
  # <https://github.com/tobie/ua-parser/blob/master/regexes.yaml>
  config :regexes, :validate => :string

  # A string to prepend to all of the extracted keys
  config :prefix, :validate => :string, :default => ''

  public
  def register
    require 'user_agent_parser'
    if @regexes.nil?
      begin
        @parser = UserAgentParser::Parser.new()
      rescue Exception => e
        begin
          if __FILE__ =~ /file:\/.*\.jar!/
            # Running from a flatjar which has a different layout
            regexes_file = [__FILE__.split("!").first, "/vendor/ua-parser/regexes.yaml"].join("!")
            @parser = UserAgentParser::Parser.new(:patterns_path => regexes_file)
          else
            # assume operating from the git checkout
            @parser = UserAgentParser::Parser.new(:patterns_path => "vendor/ua-parser/regexes.yaml")
          end
        rescue => ex
          raise "Failed to cache, due to: #{ex}\n#{ex.backtrace}"
        end
      end
    else
      @logger.info("Using user agent regexes", :regexes => @regexes)
      @parser = UserAgentParser::Parser.new(:patterns_path => @regexes)
    end
  end #def register

  public
  def filter(event)
    return unless filter?(event)
    ua_data = nil

    useragent = event[@source]
    useragent = useragent.first if useragent.is_a? Array

    begin
      ua_data = @parser.parse(useragent)
    rescue Exception => e
      @logger.error("Uknown error while parsing user agent data", :exception => e, :field => @source, :event => event)
    end

    if !ua_data.nil?
      if @target.nil?
        # default write to the root of the event
        target = event
      else
        target = event[@target] ||= {}
      end

      target[@prefix + "name"] = ua_data.name
      target[@prefix + "os"] = ua_data.os.to_s if not ua_data.os.nil?
      target[@prefix + "device"] = ua_data.device.to_s if not ua_data.device.nil?

      if not ua_data.version.nil?
        ua_version = ua_data.version
        target[@prefix + "major"] = ua_version.major
        target[@prefix + "minor"] = ua_version.minor
        target[@prefix + "patch"] = ua_version.patch if ua_version.patch
        target[@prefix + "build"] = ua_version.patch_minor if ua_version.patch_minor 
      end

      filter_matched(event)
    end

  end # def filter
end # class LogStash::Filters::UserAgent

