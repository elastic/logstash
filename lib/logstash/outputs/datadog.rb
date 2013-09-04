require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Datadog < LogStash::Outputs::Base
  # This output lets you send events (for now. soon metrics) to
  # DataDogHQ based on Logstash events
  #
  # Note that since Logstash maintains no state
  # these will be one-shot events
  #

  config_name "datadog"
  milestone 1

  # Your DatadogHQ API key
  config :api_key, :validate => :string, :required => true

  # Title
  config :title, :validate => :string, :default => "Logstash event for %{host}"

  # Text
  config :text, :validate => :string, :default => "%{message}"

  # Date Happened
  config :date_happened, :validate => :string

  # Source type name
  config :source_type_name, :validate => ["nagios", "hudson", "jenkins", "user", "my apps", "feed", "chef", "puppet", "git", "bitbucket", "fabric", "capistrano"], :default => "my apps"
 
  # Alert type
  config :alert_type, :validate => ["info", "error", "warning", "success"]

  # Priority
  config :priority, :validate => ["normal", "low"]

  # Tags
  # Set any custom tags for this event
  # Default are the Logstash tags if any
  config :dd_tags, :validate => :array

  public
  def register
    require "net/https"
    require "uri"
    @url = "https://app.datadoghq.com/api/v1/events"
    @uri = URI.parse(@url)
    @client = Net::HTTP.new(@uri.host, @uri.port)
    @client.use_ssl = true
    @client.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @logger.debug("Client", :client => @client.inspect)
  end # def register

  public
  def receive(event)
    return unless output?(event)


    dd_event = Hash.new
    dd_event['title'] = event.sprintf(@title)
    dd_event['text'] = event.sprintf(@text)
    dd_event['source_type_name'] = @source_type_name
    dd_event['alert_type'] = @alert_type if @alert_type
    dd_event['priority'] = @priority if @priority

    if @date_happened
      dd_event['date_happened'] = event.sprintf(@date_happened)
    else
      dd_event['date_happened'] = event["@timestamp"].to_i
    end

    if @dd_tags
      tagz = @dd_tags.collect {|x| event.sprintf(x) }
    else
      tagz = event["tags"]
    end
    dd_event['tags'] = tagz if tagz

    @logger.debug("DataDog event", :dd_event => dd_event)

    request = Net::HTTP::Post.new("#{@uri.path}?api_key=#{@api_key}")
    
    begin
      request.body = dd_event.to_json
      request.add_field("Content-Type", 'application/json')
      response = @client.request(request)
      @logger.info("DD convo", :request => request.inspect, :response => response.inspect)
      raise unless response.code == '200'
    rescue Exception => e
      @logger.warn("Unhandled exception", :request => request.inspect, :response => response.inspect, :exception => e.inspect)
    end
  end # def receive
end
