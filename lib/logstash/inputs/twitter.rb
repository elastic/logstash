require "logstash/inputs/base"
require "logstash/namespace"
require "tweetstream" # rubygem 'tweetstream'

class LogStash::Inputs::Twitter < LogStash::Inputs::Base

  config_name "twitter"
  config :user, :validate => :string, :required => true
  config :password, :validate => :password, :required => true

  config :keywords, :validate => :array, :required => true

  def register
    # nothing to do
  end

  public
  def run(queue)
    loop do
      stream = TweetStream::Client.new(@user, @password.value)
      stream.track(@keywords) do |status|
        @logger.debug("Got twitter status from @#{status["user"]["source"]}")
        event = LogStash::Event.new(
          "@message" => status["text"],
          "@type" => @type,
          "@tags" => @tags.clone
        )

        event.fields.merge!(
          "user" => (status["user"]["screen_name"] rescue nil), 
          "client" => (status["user"]["source"] rescue nil),
          "retweeted" => (status["retweeted"] rescue nil)
        )

        event.fields["in-reply-to"] = status["in_reply_to_status_id"] if status["in_reply_to_status_id"]

        urls = status["entities"]["urls"] rescue []
        if urls.size > 0
          event.fields["urls"] = urls.collect { |u| u["url"] }
        end

        event.source = source
        @logger.debug(["Got event", event])
        queue << event
      end # stream.track

      # Some closure or error occured, sleep and try again.
      sleep 30
    end
  end
end # class LogStash::Inputs::Twitter
