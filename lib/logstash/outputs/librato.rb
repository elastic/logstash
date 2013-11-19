# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Librato < LogStash::Outputs::Base
  # This output lets you send metrics, annotations and alerts to
  # Librato based on Logstash events
  # 
  # This is VERY experimental and inefficient right now.

  config_name "librato"
  milestone 1

  # Your Librato account
  # usually an email address
  config :account_id, :validate => :string, :required => true

  # Your Librato API Token
  config :api_token, :validate => :string, :required => true

  # Gauges
  # Send data to Librato as a gauge
  #
  # Example:
  #   ["value", "%{bytes_recieved}", "source", "%{host}", "name", "apache_bytes"]
  # Additionally, you can override the `measure_time` for the event. Must be a unix timestamp:
  #   ["value", "%{bytes_recieved}", "source", "%{host}", "name", "apache_bytes","measure_time", "%{my_unixtime_field}]
  # Default is to use the event's timestamp
  config :gauge, :validate => :hash, :default => {}

  # Counters
  # Send data to Librato as a counter
  #
  # Example:
  #   ["value", "1", "source", "%{host}", "name", "messages_received"]
  # Additionally, you can override the `measure_time` for the event. Must be a unix timestamp:
  #   ["value", "1", "source", "%{host}", "name", "messages_received", "measure_time", "%{my_unixtime_field}"]
  # Default is to use the event's timestamp
  config :counter, :validate => :hash, :default => {}

  # Annotations
  # Registers an annotation with Librato
  # The only required field is `title` and `name`.
  # `start_time` and `end_time` will be set to `event["@timestamp"].to_i`
  # You can add any other optional annotation values as well.
  # All values will be passed through `event.sprintf`
  #
  # Example:
  #   ["title":"Logstash event on %{host}", "name":"logstash_stream"]
  # or
  #   ["title":"Logstash event", "description":"%{message}", "name":"logstash_stream"]
  config :annotation, :validate => :hash, :default => {}

  # Batch size
  # Number of events to batch up before sending to Librato.
  #
  config :batch_size, :validate => :string, :default => "10"

  public
  def register
    require "net/https"
    require "uri"
    @url = "https://metrics-api.librato.com/v1/"
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

    metrics_event = Hash.new
    unless @gauge.size == 0
      g_hash = Hash[*@gauge.collect{|k,v| [k,event.sprintf(v)]}.flatten]
      g_hash.each do |k,v|
        g_hash[k] = v.to_f if k=="value"
      end
      g_hash['measure_time'] = event["@timestamp"].to_i unless g_hash['measure_time']
      @logger.warn("Gauges hash", :data => g_hash)
      metrics_event['gauges'] = Array.new 
      metrics_event['gauges'] << g_hash
      @logger.warn("Metrics hash", :data => metrics_event)
    end
    unless @counter.size == 0
      c_hash = Hash[*@counter.collect{|k,v| [k,event.sprintf(v)]}.flatten]
      c_hash.each do |k,v|
        c_hash[k] = v.to_f if k=="value"
      end
      c_hash['measure_time'] = event["@timestamp"].to_i unless c_hash['measure_time']
      @logger.warn("Counters hash", :data => c_hash)
      metrics_event['counters'] = Array.new
      metrics_event['counters'] << c_hash
      @logger.warn("Metrics hash", :data => metrics_event)
    end
   
    # TODO (lusis)
    # Clean this mess up
    unless metrics_event.size == 0
      request = Net::HTTP::Post.new(@uri.path+"metrics")
      request.basic_auth(@account_id, @api_token)
      
      begin
        request.body = metrics_event.to_json
        request.add_field("Content-Type", 'application/json')
        response = @client.request(request)
        @logger.warn("Librato convo", :request => request.inspect, :response => response.inspect)
        raise unless response.code == '200'
      rescue Exception => e
        @logger.warn("Unhandled exception", :request => request.inspect, :response => response.inspect, :exception => e.inspect)
      end
    end

    unless @annotation.size == 0
      annotation_hash = Hash.new
      annotation_hash['annotations'] = Array.new
      @logger.warn("Original Annotation", :data => @annotation)
      annotation_event = Hash[*@annotation.collect{|k,v| [event.sprintf(k),event.sprintf(v)]}.flatten]
      @logger.warn("Annotation event", :data => annotation_event)
      
      annotation_path = "#{@uri.path}annotations/#{annotation_event['name']}"
      @logger.warn("Annotation path", :data => annotation_path)
      request = Net::HTTP::Post.new(annotation_path)
      request.basic_auth(@account_id, @api_token)
      annotation_event.delete('name')
      annotation_event['start_time'] = event["@timestamp"].to_i unless annotation_event['start_time']
      annotation_event['end_time'] = event["@timestamp"].to_i unless annotation_event['end_time']
      annotation_hash['annotations'] << annotation_event
      @logger.warn("Annotation event", :data => annotation_event)

      begin
        request.body = annotation_event.to_json
        request.add_field("Content-Type", 'application/json')
        response = @client.request(request)
        @logger.warn("Librato convo", :request => request.inspect, :response => response.inspect)
        raise unless response.code == '201'
      rescue Exception => e
        @logger.warn("Unhandled exception", :request => request.inspect, :response => response.inspect, :exception => e.inspect)
      end
    end
  end # def receive
end
