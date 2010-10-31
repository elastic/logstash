require "logstash/outputs/base"
require "em-http-request"

class LogStash::Outputs::Elasticsearch < LogStash::Outputs::Base
  def initialize(url, config={}, &block)
    super
  end

  def register
    # Port?
    # Authentication?
    @httpurl = @url.clone
    @httpurl.scheme = "http"
    @http = EventMachine::HttpRequest.new(@httpurl.to_s)
  end # def register

  def receive(event)
    req = @http.post :body => event.to_json
    req.errback do
      $stderr.puts "Request to index to #{@httpurl.to_s} failed. Event was #{event.to_s}"
    end
  end # def event
end # class LogStash::Outputs::Websocket
