require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Http < LogStash::Outputs::Base
  # This output lets you `PUT` or `POST` events to a
  # generic HTTP(S) endpoint
  #
  # Additionally, you are given the option to customize
  # the headers sent as well as basic customization of the
  # event json itself.

  config_name "http"
  plugin_status "experimental"

  # URL to use
  config :url, :validate => :string, :required => :true

  # validate SSL?
  config :verify_ssl, :validate => :boolean, :default => true

  # What verb to use
  # only put and post are supported for now
  config :http_method, :validate => ["put", "post"], :required => :true

  # Custom headers to use
  # format is `headers => ["X-My-Header", "%{@source_host}"]
  config :headers, :validate => :hash

  # Content type
  config :content_type, :validate => :string, :default => "application/json"

  # Mapping
  # Normally Logstash will send the `json_event`
  # as is
  # If you provide a Logstash hash here,
  # it will be mapped into a JSON structure
  # e.g.
  # `mapping => ["foo", "%{@source_host}", "bar", "%{@type}"]
  # with generate a json like so:
  # `{"foo":"localhost.domain.com","bar":"stdin-type"}`
  config :mapping, :validate => :hash

  public
  def register
    require "net/https"
    require "uri"
    @uri = URI.parse(@url)
    @client = Net::HTTP.new(@uri.host, @uri.port)
    if @uri.scheme == "https"
      @client.use_ssl = true
      if @verify_ssl == true
        @client.verify_mode = OpenSSL::SLL::VERIFY_PEER
      else
        @client.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
  end # def register

  public
  def receive(event)
    return unless output?(event)

    if @mapping
      @evt = Hash.new
      @mapping.each do |k,v|
        @evt[k] = event.sprintf(v)
      end
    else
      @evt = event
    end

    case @http_method
    when "put"
      @request = Net::HTTP::Put.new(@uri.path)
    when "post"
      @request = Net::HTTP::Post.new(@uri.path)
    else
      @logger.error("Unknown verb:", :verb => @http_method)
    end
    
    if @headers
      @headers.each do |k,v|
        @request.add_field(k, event.sprintf(v))
      end
    end
    @request.add_field("Content-Type", @content_type)

    begin
      @request.body = @evt.to_json
      response = @client.request(@request)
    rescue Exception => e
      @logger.warn("Unhandled exception", :request => @request, :response => @response)
    end
  end # def receive
end
