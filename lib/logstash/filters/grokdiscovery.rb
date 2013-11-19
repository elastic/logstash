# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# TODO(sissel): This is not supported yet. There is a bug in grok discovery
# that causes segfaults in libgrok.
class LogStash::Filters::Grokdiscovery < LogStash::Filters::Base

  config_name "grokdiscovery"
  milestone 1

  public
  def initialize(config = {})
    super

    @discover_fields = {}
  end # def initialize

  public
  def register
    gem "jls-grok", ">=0.4.3"
    require "grok" # rubygem 'jls-grok'

    # TODO(sissel): Make patterns files come from the config
    @config.each do |type, typeconfig|
      @logger.debug("Registering type with grok: #{type}")
      @grok = Grok.new
      Dir.glob("patterns/*").each do |path|
        @grok.add_patterns_from_file(path)
      end
      @discover_fields[type] = typeconfig
      @logger.debug(["Enabling discovery", { :type => type, :fields => typeconfig }])
      @logger.warn(@discover_fields)
    end # @config.each
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    # parse it with grok
    message = event["message"]
    match = false

    if event.type and @discover_fields.include?(event.type)
      discover = @discover_fields[event.type] & event.to_hash.keys
      discover.each do |field|
        value = event[field]
        value = [value] if value.is_a?(String)

        value.each do |v| 
          pattern = @grok.discover(v)
          @logger.warn("Trying #{v} => #{pattern}")
          @grok.compile(pattern)
          match = @grok.match(v)
          if match
            @logger.warn(["Match", match.captures])
            event.to_hash.merge!(match.captures) do |key, oldval, newval|
              @logger.warn(["Merging #{key}", oldval, newval])
              oldval + newval # should both be arrays...
            end
          else
            @logger.warn(["Discovery produced something not matchable?", { :input => v }])
          end
        end # value.each
      end # discover.each
    else
      @logger.info("Unknown type for #{event.source} (type: #{event.type})")
      @logger.debug(event.to_hash)
    end
    @logger.debug(["Event now: ", event.to_hash])

    filter_matched(event) if !event.cancelled?
  end # def filter
end # class LogStash::Filters::Grokdiscovery
