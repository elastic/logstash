require "logstash/namespace"
require "logstash/event"
require "uri"
require "em-http-request"

class LogStash::Outputs::Elasticsearch
  def initialize(url, config={}, &block)
    @url = url
    @url = URI.parse(url) if url.is_a? String
    @config = config
  end

  def register
    # Port?
    # Authentication?
    @httpurl = @url.clone
    @httpurl.scheme = "http"
    @http = EventMachine::HttpRequest.new(@httpurl.to_s)
  end # def register

  def receive(event)
    #http = EventMachine::HttpRequest.new(@httpurl.to_s).post :body => event.to_json
    req = @http.post :body => event.to_json
    req.errback do
      $stderr.puts "Request to index to #{@httpurl.to_s} failed. Event was #{event.to_s}"
    end
  end # def event
end # class LogStash::Outputs::Websocket
