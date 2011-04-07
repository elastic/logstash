require "logstash/filters/base"
require "logstash/namespace"

gem "jls-grok", ">=0.2.3071"
require "grok" # rubygem 'jls-grok'

class LogStash::Filters::Grok < LogStash::Filters::Base
  public
  def initialize(config = {})
    super

    @grokpiles = {}
  end # def initialize

  public
  def register
    # TODO(sissel): Make patterns files come from the config
    @config.each do |type, typeconfig|
      @logger.debug("Registering type with grok: #{type}")
      pile = Grok::Pile.new
      patterndir = "#{File.dirname(__FILE__)}/../../../patterns/*"
      Dir.glob(patterndir).each do |path|
        pile.add_patterns_from_file(path)
      end
      typeconfig["patterns"].each do |pattern|
        groks = pile.compile(pattern)
        @logger.debug(["Compiled pattern", pattern, groks[-1].expanded_pattern])
      end
      @grokpiles[type] = pile
    end # @config.each
  end # def register

  public
  def filter(event)
    # parse it with grok
    message = event.message
    match = false

    if event.type
      if @grokpiles.include?(event.type)
        @logger.debug(["Running grok filter", event])
        pile = @grokpiles[event.type]
        grok, match = pile.match(message)
      end # @grokpiles.include?(event.type)
      # TODO(2.0): support grok pattern discovery
    else
      @logger.info("Unknown type for #{event.source} (type: #{event.type})")
      @logger.debug(event.to_hash)
    end

    if match
      match.each_capture do |key, value|
        match_type = nil
        if key.include?(":")
          name, key, match_type = key.split(":")
        end

        # http://code.google.com/p/logstash/issues/detail?id=45
        # Permit typing of captures by giving an additional colon and a type,
        # like: %{FOO:name:int} for int coercion.
        case match_type
          when "int"
            value = value.to_i
          when "float"
            value = value.to_f
        end

        if event.message == value
          # Skip patterns that match the entire line
          @logger.debug("Skipping capture '#{key}' since it matches the whole line.")
          next
        end

        if event.fields[key].is_a?(String)
          event.fields[key] = [event.fields[key]]
        elsif event.fields[key] == nil
          event.fields[key] = []
        end

        # If value is not nil, or responds to empty and is not empty, add the
        # value to the event.
        if !value.nil? && (!value.empty? rescue true)
          event.fields[key] << value
        end
      end
    else
      # Tag this event if we can't parse it. We can use this later to
      # reparse+reindex logs if we improve the patterns given .
      event.tags << "_grokparsefailure"
    end

    @logger.debug(["Event now: ", event.to_hash])
  end # def filter
end # class LogStash::Filters::Grok
