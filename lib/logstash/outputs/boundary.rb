# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Boundary < LogStash::Outputs::Base
  # This output lets you send annotations to
  # Boundary based on Logstash events
  #
  # Note that since Logstash maintains no state
  # these will be one-shot events
  #
  # By default the start and stop time will be
  # the event timestamp
  #

  config_name "boundary"
  milestone 1

  # Your Boundary API key
  config :api_key, :validate => :string, :required => true

  # Your Boundary Org ID
  config :org_id, :validate => :string, :required => true

  # Type
  config :btype, :validate => :string

  # Sub-Type
  config :bsubtype, :validate => :string

  # Tags
  # Set any custom tags for this event
  # Default are the Logstash tags if any
  config :btags, :validate => :array

  public
  def register
    require "net/https"
    require "uri"
    @url = "https://api.boundary.com/#{@org_id}/events"
    @uri = URI.parse(@url)
    @client = Net::HTTP.new(@uri.host, @uri.port)
    @client.use_ssl = true
  end # def register

  public
  def receive(event)
    return unless output?(event)

    boundary_event = {
	:createdAt => event["@timestamp"],
        :fingerprintFields => ["@title"],
	:source => {
            :ref => event["host"],
            :type => "host"
        },
	:sender => {
            :ref => "Logstash",
            :type => "application"
        },
	:properties => event
    }

    boundary_event['title'] = event.sprintf(@btype) if @btype
    boundary_event['message'] = event.sprintf(@bsubtype) if @bsubtype
    boundary_event['tags'] = @btags.collect { |x| event.sprintf(x) } if @btags

    boundary_event['title'] = event['message'] if event['message']
    boundary_event['message'] = event['type'] if event['type']
    boundary_event['tags'] = event['tags'] if event['tags']

    request = Net::HTTP::Post.new(@uri.path)
    request.basic_auth(@api_key, '')

    @logger.debug("Boundary event", :boundary_event => boundary_event)

    begin
      request.body = boundary_event.to_json
      request.add_field("Content-Type", 'application/json')
      response = @client.request(request)
      @logger.warn("Boundary convo", :request => request.inspect, :response => response.inspect)
      raise unless response.code == '201'
    rescue Exception => e
      @logger.warn(
        "Unhandled exception",
        :request => request.inspect,
        :response => response.inspect,
        :exception => e.inspect
      )
    end
  end # def receive
end
