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
  plugin_status "experimental"

  # Your Boundary API key
  config :api_key, :validate => :string, :required => true

  # Your Boundary Org ID
  config :org_id, :validate => :string, :required => true

  # Start time
  # Override the start time
  # Note that Boundary requires this to be seconds since epoch
  # If overriding, it is your responsibility to type this correctly
  # By default this is set to `event.unix_timestamp.to_i`
  config :start_time, :validate => :string

  # End time
  # Override the stop time
  # Note that Boundary requires this to be seconds since epoch
  # If overriding, it is your responsibility to type this correctly
  # By default this is set to `event.unix_timestamp.to_i`
  config :end_time, :validate => :string

  # Type
  config :btype, :validate => :string

  # Sub-Type
  config :bsubtype, :validate => :string

  # Tags
  # Set any custom tags for this event
  # Default are the Logstash tags if any
  config :btags, :validate => :array

  # Auto
  # If set to true, logstash will try to pull boundary fields out
  # of the event. Any field explicitly set by config options will
  # override these.
  # ['type', 'subtype', 'creation_time', 'end_time', 'links', 'tags', 'loc']
  config :auto, :validate => :bool, :default => false

  public
  def register
    require "net/https"
    require "uri"
    @url = "https://api.boundary.com/#{@org_id}/annotations"
    @uri = URI.parse(@url)
    @client = Net::HTTP.new(@uri.host, @uri.port)
    @client.use_ssl = true
    # Boundary cert doesn't verify
    @client.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end # def register

  public
  def receive(event)
    return unless output?(event)

    boundary_event = Hash.new
    boundary_keys = ['type', 'subtype', 'creation_time', 'end_time', 'links', 'tags', 'loc']

    boundary_event['start_time'] = event.sprintf(@start_time) if @start_time
    boundary_event['end_time'] = event.sprintf(@end_time) if @end_time
    boundary_event['type'] = event.sprintf(@btype) if @btype
    boundary_event['subtype'] = event.sprintf(@bsubtype) if @bsubtype
    boundary_event['tags'] = @btags.collect { |x| event.sprintf(x) } if @btags

    if @auto
      boundary_fields = event['@fields'].select { |k| boundary_keys.member? k }
      boundary_event = boundary_fields.merge boundary_event
    end

    boundary_event = {
      'type' => event.sprintf("%{message}"),
      'subtype' => event.sprintf("%{type}"),
      'start_time' => event.unix_timestamp.to_i,
      'end_time' => event.unix_timestamp.to_i,
      'links' => [],
      'tags' => event.tags,
    }.merge boundary_event

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
