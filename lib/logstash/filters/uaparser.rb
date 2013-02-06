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
class LogStash::Filters::UAParser < LogStash::Filters::Base
  config_name "uaparser"
  plugin_status "experimental"

  # The field containing the user agent string. If this field is an
  # array, only the first value will be used.
  config :source, :validate => :string, :required => true

  # The name of the field to assign the UA data hash to
  config :target, :validate => :string, :default => "ua"

  # regexes.yaml file to use
  #
  # If not specified, this will default to the regexes.yaml that ships
  # with logstash.
  config :regexes, :validate => :string

  public
  def register
    require 'user_agent_parser'
    if @regexes.nil?
      begin
        @parser = UserAgentParser::Parser.new()
      rescue Exception => e
        begin
          # Running from a flatjar which has a different layout
          jar_path = [__FILE__.split("!").first, "/vendor/ua-parser/regexes.yaml"].join("!")
          tmp_file = Tempfile.new('logstash-uaparser-regexes')
          tmp_file.write(File.read(jar_path))
          tmp_file.close # this file is reaped when ruby exits
          @parser = UserAgentParser::Parser.new(tmp_file.path)
        rescue => ex
          raise "Failed to cache, due to: #{ex}\n#{ex.backtrace}"
        end
      end
    else
      @logger.info("Using user agent regexes", :regexes => @regexes)
      @parser = UserAgentParser::Parser.new(@regexes)
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

    unless ua_data.nil?
        event[@target] = {} if event[@target].nil?

        event[@target]["name"] = ua_data.name
        event[@target]["os"] = ua_data.os if not ua_data.os.nil?
        event[@target]["device"] = ua_data.device if not ua_data.device.nil?

        if not ua_data.version.nil?
          ua_version = ua_data.version

          event[@target]["major"] = ua_version.major
          event[@target]["minor"] = ua_version.minor
        end

      filter_matched(event)
    end

  end # def filter
end # class LogStash::Filters::UAParser

