require "logstash/namespace"
require "logstash/event"
require "logstash/logging"
require "uri"

class LogStash::Outputs::Base
  def initialize(url, config={}, &block)
    @url = url
    @url = URI.parse(url) if url.is_a? String
    @config = config
    @logger = LogStash::Logger.new(STDOUT)
    @urlopts = {}
    if @url.query
      @urlopts = CGI.parse(@url.query)
      @urlopts.each do |k, v|
        @urlopts[k] = v.last if v.is_a?(Array)
      end
    end
  end

  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  def receive(event)
    raise "#{self.class}#receive must be overidden"
  end
end # class LogStash::Outputs::Base
