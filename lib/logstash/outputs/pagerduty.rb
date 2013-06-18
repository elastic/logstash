require "logstash/outputs/base"
require "logstash/namespace"

# PagerDuty output
# Send specific events to PagerDuty for alerting

class LogStash::Outputs::PagerDuty < LogStash::Outputs::Base
  config_name "pagerduty"
  milestone 1

  # Service API Key
  config :service_key, :validate => :string, :required => true

  # The service key to use
  # You'll need to set this up in PD beforehand
  config :incident_key, :validate => :string, :default => "logstash/%{@source_host}/%{@type}"

  # Event type
  config :event_type, :validate => ["trigger", "acknowledge", "resolve"], :default => "trigger"

  # Custom description
  config :description, :validate => :string, :default => "Logstash event for %{@source_host}"

  # Event details
  # These might be keys from the logstash event you wish to include
  # tags are automatically included if detected so no need to add them here
  config :details, :validate => :hash, :default => {"timestamp" => "%{@timestamp}", "message" => "%{@message}"}

  # PagerDuty API url
  # You shouldn't need to change this
  # This allows for flexibility
  # should PD iterate the API
  # and Logstash hasn't updated yet
  config :pdurl, :validate => :string, :default => "https://events.pagerduty.com/generic/2010-04-15/create_event.json"

  public
  def register
    require 'net/https'
    require 'uri'
    @pd_uri = URI.parse(@pdurl)
    @client = Net::HTTP.new(@pd_uri.host, @pd_uri.port)
    if @pd_uri.scheme == "https"
      @client.use_ssl = true
      #@client.verify_mode = OpenSSL::SSL::VERIFY_PEER
      # PagerDuty cert doesn't verify oob
      @client.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end # def register

  public
  def receive(event)
    return unless output?(event)
   
    pd_event = Hash.new
    pd_event[:service_key] = "#{@service_key}"
    pd_event[:incident_key] = event.sprintf(@incident_key)
    pd_event[:event_type] = "#{@event_type}"
    pd_event[:description] = event.sprintf(@description)
    pd_event[:details] = Hash.new
    @details.each do |key, value|
      @logger.debug("PD Details added:" , key => event.sprintf(value))
      pd_event[:details]["#{key}"] = event.sprintf(value)
    end
    pd_event[:details][:tags] = @tags if @tags

    @logger.info("PD Event", :event => pd_event)
    begin
      request = Net::HTTP::Post.new(@pd_uri.path)
      request.body = pd_event.to_json
      @logger.debug("PD Request", :request => request.inspect)
      response = @client.request(request)
      @logger.debug("PD Response", :response => response.body)

    rescue Exception => e
      @logger.debug("PD Unhandled exception", :pd_error => e.backtrace)
    end
  end # def receive
end # class LogStash::Outputs::PagerDuty
