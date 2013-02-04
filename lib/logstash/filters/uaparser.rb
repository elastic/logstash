require "logstash/filters/base"
require "logstash/namespace"

# This filter can parse user agent strings in to structured data
class LogStash::Filters::UAParser < LogStash::Filters::Base
  config_name "uaparser"
  plugin_status "experimental"

  # The field containing the user agent string to parse
  config :field, :validate => :string

  # The name of the field to assign the UA data hash to
  config :container, :validate => :string, :default => "ua"

  # name with full path of BrowserScope YAML file.
  # One is shipped with this filter, but you can reference
  # updated versions here. See https://github.com/tobie/ua-parser
  # for updates
  config :regexes_path, :validate => :string

  public
  def register
    require 'user_agent_parser'

    if @regexes_path.nil?
        @parser = UserAgentParser::Parser.new
    else
        @logger.info? and @logger.info "Using regexes from",  :regexes_path => @regexes_path)
        @parser = UserAgentParser::Parser.new(regexes_path)
    end
  end #def register

  public
  def filter(event)
    return unless filter?(event)

    result = @parser.parse event[@field]

    ua = {}
    ua['name'] = result.name

    if not result.os.nil?
      ua['os'] = result.os
    end

    if not result.device.nil?
      ua['device'] = result.device
    end

    if not result.version.nil?
      ua_version = result.version

      ua['major'] = ua_version.major
      ua['minor'] = ua_version.minor
    end

    event[@container] = ua

    filter_matched(event)
  end # def filter
end # class LogStash::Filters::UAParser

