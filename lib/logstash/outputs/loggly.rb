require "logstash/outputs/base"
require "logstash/namespace"
require "uri"

# TODO(sissel): Move to something that performs better than net/http
require "net/http"

class LogStash::Outputs::Loggly < LogStash::Outputs::Base
  config_name "loggly"

  # The hostname to send logs to. This should target the loggly http input
  # server which is usually "logs.loggly.com"
  #config :url, :validate => :string, :default => "https://logs.loggly.com/"
  config :host, :validate => :string, :default => "logs.loggly.com"

  # The loggly http input key to send to.
  # This is usually visible in the Loggly 'Inputs' page as something like this
  #     https://logs.hoover.loggly.net/inputs/abcdef12-3456-7890-abcd-ef0123456789
  #                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #                                                   ^       key        ^
  #
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
    #url = URI.parse("#{@url}inputs/#{@key}")
    url = URI.parse("http://#{@host}/inputs/#{@key}")
    @logger.info("Loggly URL: #{url}")
    request = Net::HTTP::Post.new(url.path)
    request.body = event.to_json
    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(request) }
    if response == Net::HTTPSuccess
      @logger.info("Event send to Loggly OK!")
    else
      @logger.info response.error!
    end
  end # def receive
end # class LogStash::Outputs::Loggly
