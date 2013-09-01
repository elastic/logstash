require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Circonus < LogStash::Outputs::Base
  # This output lets you send annotations to
  # Circonus based on Logstash events
  # 

  config_name "circonus"
  milestone 1

  # Your Circonus API Token
  config :api_token, :validate => :string, :required => true

  # Your Circonus App name
  # This will be passed through `event.sprintf`
  # so variables are allowed here:
  #
  # Example:
  #  `app_name => "%{myappname}"`
  config :app_name, :validate => :string, :required => true

  # Annotations
  # Registers an annotation with Circonus
  # The only required field is `title` and `description`.
  # `start` and `stop` will be set to `event["@timestamp"]`
  # You can add any other optional annotation values as well.
  # All values will be passed through `event.sprintf`
  #
  # Example:
  #   ["title":"Logstash event", "description":"Logstash event for %{host}"]
  # or
  #   ["title":"Logstash event", "description":"Logstash event for %{host}", "parent_id", "1"]
  config :annotation, :validate => :hash, :required => true, :default => {}

  public
  def register
    require "net/https"
    require "uri"
    @url = "https://circonus.com/api/json/"
    @uri = URI.parse(@url)
    @client = Net::HTTP.new(@uri.host, @uri.port)
    @client.use_ssl = true
    @client.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
  end # def register

  public
  def receive(event)
    # TODO (lusis)
    # batch and flush
    return unless output?(event)
   
    annotation_event = Hash[*@annotation.collect{|k,v| [event.sprintf(k),event.sprintf(v)]}.flatten]
    @logger.warn("Annotation event", :data => annotation_event)
  
    annotation_array = []
    annotation_path = "#{@uri.path}annotation"
    @logger.warn("Annotation path", :data => annotation_path)
    request = Net::HTTP::Post.new(annotation_path)
    annotation_event['start'] = event["@timestamp"].to_i unless annotation_event['start']
    annotation_event['stop'] = event["@timestamp"].to_i unless annotation_event['stop']
    @logger.warn("Annotation event", :data => annotation_event)
    annotation_array << annotation_event
    begin
      request.set_form_data(:annotations => annotation_array.to_json)
      @logger.warn(annotation_event)
      request.add_field("X-Circonus-Auth-Token", "#{@api_token}")
      request.add_field("X-Circonus-App-Name", "#{event.sprintf(@app_name)}")
      response = @client.request(request)
      @logger.warn("Circonus convo", :request => request.inspect, :response => response.inspect)
      raise unless response.code == '200'
    rescue Exception => e
      @logger.warn("Unhandled exception", :request => request.inspect, :response => response.inspect, :exception => e.inspect)
    end
  end # def receive
end
