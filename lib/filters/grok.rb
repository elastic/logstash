require "logstash/namespace"
require "grok" # rubygem 'grok'

class LogStash::Filters::Grok
  def initialize(config = {})
    @config = config
    @grok = Grok.new
  end # def initialize

  def register
    @grok.add_patterns_from_file("patterns/grok-patterns")
  end

  def filter(event)
    # parse it with grok
    message = event.message
    pattern = @grok.discover(message)
    @grok.compile(pattern)
    match = @grok.match(message)
    match.each_capture do |key, value|
      if key.include?(":")
        key = key.split(":")[1]
      end

      if event[key].is_a? String
        event[key] = [event[key]]
      elsif event[key] == nil
        event[key] = []
      end

      event[key] << value
    end
    
    # TODO(sissel): Flatten single-entry arrays into a single value?
    return event
  end
end # class LogStash::Filters::Grok
