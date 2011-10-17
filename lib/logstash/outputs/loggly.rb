require "logstash/outputs/base"
require "logstash/namespace"
require "uri"

# TODO(sissel): Move to something that performs better than net/http
require "net/http"

# Got a loggly account? Use logstash to ship logs to Loggly!
#
# This is most useful so you can use logstash to parse and structure
# your logs and ship structured, json events to your account at Loggly.
#
# To use this, you'll need to use a Loggly input with type 'http'
# and 'json logging' enabled.
class LogStash::Outputs::Loggly < LogStash::Outputs::Base
  config_name "loggly"

  # The hostname to send logs to. This should target the loggly http input
  # server which is usually "logs.loggly.com"
  config :host, :validate => :string, :default => "logs.loggly.com"

  # The loggly http input key to send to.
  # This is usually visible in the Loggly 'Inputs' page as something like this
  #     https://logs.hoover.loggly.net/inputs/abcdef12-3456-7890-abcd-ef0123456789
  #                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #                                           \---------->   key   <-------------/
  #
  # You can use %{foo} field lookups here if you need to pull the api key from
  # the event. This is mainly aimed at multitenant hosting providers who want
  # to offer shipping a customer's logs to that customer's loggly account.
  config :key, :validate => :string, :required => true

  public
  def register
    # nothing to do
  end

  public
  def receive(event)
    if event == LogStash::SHUTDOWN
      finished
      return
    end

    # Send the event over http.
    url = URI.parse("http://#{@host}/inputs/#{event.sprintf(@key)}")
    @logger.info("Loggly URL", :url => url)
    request = Net::HTTP::Post.new(url.path)
    request.body = event.to_json
    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(request) }
    if response == Net::HTTPSuccess
      @logger.info("Event send to Loggly OK!")
    else
      @logger.info("HTTP error", :error => response.error!)
    end
  end # def receive
end # class LogStash::Outputs::Loggly
