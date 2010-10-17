require "logstash/namespace"
require "logstash/event"
require "uri"

class LogStash::Outputs::Stdout
  def initialize(url, config={}, &block)
    @url = url
    @url = URI.parse(url) if url.is_a? String
    @config = config
  end

  def register
    # nothing to do
  end # def register

  def receive(event)
    puts event
  end # def event
end # class LogStash::Outputs::Stdout
