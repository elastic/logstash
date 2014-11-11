# encoding: utf-8
require "logstash/namespace"

# This output allows you to write events to [slack](https://api.slack.com/).
#
class LogStash::Outputs::Slack < LogStash::Outputs::Base

  config_name "slack"
  milestone 1

  # The Slack authentication token.
  config :token, :validate => :string, :required => true

  # The ID or name of the channel.
  config :channel, :validate => :string, :required => true

  # The name the message will appear be sent from.
  config :from, :validate => :string, :default => "logstash"

  # Message format to send, event tokens are usable here.
  config :format, :validate => :string, :default => "%{message}"

  # Icon to use for message sent.
  config :icon_url, :validate => :string, :default => false

  public
  def register
    require "ftw"
    require "uri"

    @agent = FTW::Agent.new

    @api_message = "https://api.slack.com/api/chat.postMessage?"

  end # def register

  public
  def receive(event)
    return unless output?(event)

    slack_data = Hash.new
    slack_data['token'] = @token
    slack_data['channel'] = @channel
    slack_data['username'] = @from
    slack_data['text'] = event.sprintf(@format)
    slack_data['icon_url'] = @icon_url unless not icon_url

    @logger.debug("Slack data", :slack_data => slack_data)

    begin

      url =  @api_message + encode(slack_data)
      request = @agent.get(url)

      response = @agent.execute(request)

      # Consume body to let this connection be reused
      rbody = ""
      response.read_body { |c| rbody << c }
      puts url
    rescue Exception => e
      @logger.warn("Unhandled exception", :request => request, :response => response, :exception => e, :stacktrace => e.backtrace)
    end
  end # def receive

  # shamelessly lifted this from the LogStash::Outputs::Http, I'd rather put this
  # in a common place for both to use, but unsure where that place is or should be
  def encode(hash)
    return hash.collect do |key, value|
      CGI.escape(key) + "=" + CGI.escape(value)
    end.join("&")
  end # def encode

end # class LogStash::Outputs::Slack
