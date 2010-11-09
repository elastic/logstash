require "logstash/filters/base"

gem "jls-grok", ">=0.2.3071"
require "grok" # rubygem 'jls-grok'

class LogStash::Filters::Grokdiscovery < LogStash::Filters::Base
  def initialize(config = {})
    super

    @discover_fields = {}
  end # def initialize

  def register
    # TODO(sissel): Make patterns files come from the config
    @config.each do |type, typeconfig|
      @logger.debug("Registering type with grok: #{type}")
      @grok = Grok.new
      Dir.glob("patterns/*").each do |path|
        @grok.add_patterns_from_file(path)
      end
      typeconfig.each do |type, fields|
        @discover_fields[type] = fields
        @logger.debug("Enabling discovery", { :type => type, :fields => fields })
      end
    end # @config.each
  end # def register

  def filter(event)
    # parse it with grok
    message = event.message
    match = false

    if event.type and @discover_fields.include?(event.type)

      discover = @discover_fields[event.type] & event.fields.keys
      discover.each do |field|
        value = event.fields[field]
        pattern = @grok.discover(value)
        @grok.compile(pattern)
        match = @grok.match(value)
        if match
          event.fields.merge(match.captures) do |key, oldval, newval|
            oldval + newval # should both be arrays...
          end
        else
          @logger.warn(["Discovery produced something not matchable?", { :input => value }])
        end
      end # discover.each
    else
      @logger.info("Unknown type for #{event.source} (type: #{event.type})")
      @logger.debug(event.to_hash)
    end
    @logger.debug(["Event now: ", event.to_hash])
  end # def filter
end # class LogStash::Filters::Grokdiscovery
