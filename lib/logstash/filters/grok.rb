require "logstash/namespace"

gem "jls-grok", ">=0.2.3071"
require "grok" # rubygem 'jls-grok'

class LogStash::Filters::Grok
  def initialize(config = {})
    @config = config
    @grokpiles = {}
  end # def initialize

  def register
    # TODO(sissel): Make patterns files come from the config
    @config.each do |tag, tagconfig|
      pile = Grok::Pile.new
      pile.add_patterns_from_file("patterns/grok-patterns")
      pile.add_patterns_from_file("patterns/linux-syslog")
      tagconfig["patterns"].each do |pattern|
        pile.compile(pattern)
      end
      @grokpiles[tag] = pile
    end # @config.each
  end # def register

  def filter(event)
    # parse it with grok
    message = event.message
    match = false

    if event.include?("tags")
      event["tags"].each do |tag|
        if @grokpiles.include?(tag)
          pile = @grokpiles[tag]
          grok, match = pile.match(message)
          break if match
        end # @grokpiles.include?(tag)
      end # event["tags"].each
    else 
      #pattern = @grok.discover(message)
      #@grok.compile(pattern)
      #match = @grok.match(message)
    end

    if match
      match.each_capture do |key, value|
        if key.include?(":")
          key = key.split(":")[1]
        end

        if event[key].is_a?(String)
          event[key] = [event[key]]
        elsif event[key] == nil
          event[key] = []
        end

        event[key] << value
      end
    else
      event["PARSEFAILURE"] = 1
    end
    
    # TODO(sissel): Flatten single-entry arrays into a single value?
    return event
  end
end # class LogStash::Filters::Grok
