require "logstash/inputs/base"
require "em-http-request"
require "cgi"

class LogStash::Inputs::Twitter < LogStash::Inputs::Base
  def register
    api_url = "https://stream.twitter.com/1/statuses/filter.json"
    @http = EventMachine::HttpRequest.new(api_url)
    @logger.info(["Registering input", { :url => @url, :api_url => api_url, :params => @urlopts }])
    source = "twitter://...#{@url.path}?#{@url.query}"

    req = nil
    connect = proc do
      @logger.info(["Connecting", { :url => @url, :api_url => api_url, :params => @urlopts}])
      req = @http.post :body => @urlopts,
                       :head => { "Authorization" => [ @url.user, @url.password ] }
      buffer = BufferedTokenizer.new

      req.stream do |chunk|
        buffer.extract(chunk).each do |line|
          tweet = JSON.parse(line)
          next if !tweet

          event = LogStash::Event.new
          event.message = tweet["text"]
          event.fields.merge!(
            "user" => (tweet["user"]["screen_name"] rescue nil),
            "client" => (tweet["user"]["source"] rescue nil),
            "retweeted" => (tweet["retweeted"] rescue nil)
          )

          event.fields["in-reply-to"] = tweet["in_reply_to_status_id"] if tweet["in_reply_to_status_id"]

          urls = tweet["entities"]["urls"] rescue []
          if urls.size > 0
            event.fields["urls"] = urls.collect { |u| u["url"] }
          end

          event.source = source
          @logger.debug(["Got event", event])
          @callback.call(event)
        end # buffer.extract
      end # req.stream

      req.errback do
        @logger.warn(["Error occurred, not sure what, seriously. Reconnecting!", { :url => @url }])

        EventMachine::Timer.new(5) do
          connect.call
        end
      end # req.errback

      req.callback do
        @logger.warn(["Request completed. Unexpected!", { :url => @url }])
      end
    end # connect = proc do

    connect.call
  end # def register
end # class LogStash::Inputs::Twitter
