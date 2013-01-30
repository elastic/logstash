require "logstash/inputs/base"
require "logstash/namespace"
require "net/http"
require "json"
#require "net/https"

# Read events from the twitter streaming api.
class LogStash::Inputs::Twitter < LogStash::Inputs::Base

  config_name "twitter"
  plugin_status "beta"

  # Your twitter username
  config :user, :validate => :string, :required => true

  # Your twitter password
  config :password, :validate => :password, :required => true

  # Any keywords to track in the twitter stream
  config :keywords, :validate => :array, :required => true

  # Proxy Host
  config :proxy_host, :validate => :string

  # Proxy Port
  config :proxy_port, :validate => :number

  # Proxy Username
  config :proxy_user, :validate => :string

  # Proxy Password
  config :proxy_password, :validate => :password

  public
  def initialize(params)
    super

    # Force format to plain. Other values don't make any sense here.
    @format = "plain"
  end # def initialize

  public
  def register
    # TODO(sissel): put buftok in logstash, too
    @logger.info("Registering twitter input")
    v = require("filewatch/buftok")
    @logger.info("Required buftok #{v}")
    #require "tweetstream" # rubygem 'tweetstream'
  end

  public
  def run(queue)
    loop do
      #stream = TweetStream::Client.new(@user, @password.value)
      #stream.track(*@keywords) do |status|
      track(*@keywords) do |status|
        @logger.debug("twitter keyword track status", :status => status)
        #@logger.debug("Got twitter status from @#{status[:user][:screen_name]}")
        @logger.info("Got twitter status", :user => status["user"]["screen_name"])
        e = to_event(status["text"], "http://twitter.com/#{status["user"]["screen_name"]}/status/#{status["id"]}")
        next unless e

        e.fields.merge!(
          "user" => (status["user"]["screen_name"] rescue nil),
          "client" => (status["source"] rescue nil),
          "retweeted" => (status["retweeted"] rescue nil)
        )

        e.fields["in-reply-to"] = status["in_reply_to_status_id"] if status["in_reply_to_status_id"]

        urls = status["entities"]["urls"] rescue []
        if urls.size > 0
          e.fields["urls"] = urls.collect { |u| u["url"] }
        end

        queue << e
      end # stream.track

      # Some closure or error occured, sleep and try again.
      @logger.warn("An error occured? Retrying twitter in 30 seconds")
      sleep 30
    end # loop
  end # def run

  private
  def track(*keywords)
    uri = URI.parse("https://stream.twitter.com/1/statuses/filter.json")
    #params = {
      #"track" => keywords
    #}

    http = Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_password.value).new(uri.host, uri.port)
    http.use_ssl = true

    # TODO(sissel): Load certs.
    http.ca_file = File.join(File.dirname(__FILE__), "..", "certs", "cacert.pem")
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.verify_depth = 5

    request = Net::HTTP::Post.new(uri.path)
    request.body = "track=#{keywords.join(",")}"
    request.basic_auth @user, @password.value
    buffer = FileWatch::BufferedTokenizer.new("\r\n")
    http.request(request) do |response|
      response.read_body do |chunk|
        #@logger.info("Twitter: #{chunk.inspect}")
        buffer.extract(chunk).each do |line|
          @logger.info("Twitter line", :line => line)
          begin 
            # Ignore blank lines twitter sometimes sends
            next if line == ""
            status = JSON.parse(line)
            yield status
          rescue => e
            @logger.error("Error parsing json from twitter", :exception => e,
                          :backtrace => e.backtrace);
          end
        end # buffer.extract
      end # response.read_body
    end # http.request
  end # def track
end # class LogStash::Inputs::Twitter
