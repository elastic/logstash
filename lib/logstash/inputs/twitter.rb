require "logstash/inputs/base"
require "logstash/namespace"
require "net/http"
require "json"
#require "net/https"

# Read events from the twitter streaming api.
class LogStash::Inputs::Twitter < LogStash::Inputs::Base

  config_name "twitter"
  milestone 1

  # Your twitter app's consumer key
  #
  # Don't know what this is? You need to create an "application"
  # on twitter, see this url: <https://dev.twitter.com/apps/new>
  config :consumer_key, :validate => :string, :required => true

  # Your twitter app's consumer secret
  #
  # If you don't have one of these, you can create one by
  # registering a new application with twitter:
  # <https://dev.twitter.com/apps/new>
  config :consumer_secret, :validate => :password, :required => true

  # Your oauth token.
  #
  # To get this, login to twitter with whatever account you want,
  # then visit <https://dev.twitter.com/apps>
  #
  # Click on your app (used with the consumer_key and consumer_secret settings)
  # Then at the bottom of the page, click 'Create my access token' which
  # will create an oauth token and secret bound to your account and that
  # application.
  config :oauth_token, :validate => :string, :required => true
  
  # Your oauth token secret.
  #
  # To get this, login to twitter with whatever account you want,
  # then visit <https://dev.twitter.com/apps>
  #
  # Click on your app (used with the consumer_key and consumer_secret settings)
  # Then at the bottom of the page, click 'Create my access token' which
  # will create an oauth token and secret bound to your account and that
  # application.
  config :oauth_token_secret, :validate => :password, :required => true

  # Any keywords to track in the twitter stream
  config :keywords, :validate => :array, :required => true

  public
  def register
    raise LogStash::ConfigurationError, "Sorry, this plugin doesn't work anymore. We will fix it eventually, but if you need this plugin, please file a ticket on logstash.jira.com :)"

    require "tweetstream"
    TweetStream.configure do |c|
      c.consumer_key = @consumer_key
      c.consumer_secret = @consumer_secret.value
      c.oauth_token = @oauth_token
      c.oauth_token_secret = @oauth_token_secret.value
      c.auth_method = :oauth
    end
  end

  public
  def run(queue)
    client = TweetStream::Client.new
    @logger.info("Starting twitter tracking", :keywords => @keywords)
    client.track(*@keywords) do |status|
      @logger.info? && @logger.info("Got tweet", :user => status.user.screen_name, :text => status.text)
      event = LogStash::Event.new(
        "user" => status.user.screen_name,
        "client" => status.source,
        "retweeted" => status.retweeted
      )
      event["in-reply-to"] = status.in_reply_to_status_id  if status.in_reply_to_status_id
      #urls = tweet.urls.collect(&:expanded_url)
      #event["urls"] = urls if urls.size > 0
      queue << event
    end # client.track
  end # def run
end # class LogStash::Inputs::Twitter
