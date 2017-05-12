# encoding: utf-8
require "logstash/namespace"
require "logstash/outputs/http"

#Shamelessly ripped off of the logstash/hipchat output.

# This output allows you to write events to [Zulip](https://www.zulip.com/).
#
class LogStash::Outputs::Zulip < LogStash::Outputs::Base

  config_name "zulip"
  milestone 1

  # The Zulip authentication bot username.
  config :user, :validate => :string, :required => true
  
  # The Zulip authentication key.
  config :password, :validate => :password, :required => true

  # type - stream or private.
  config :zuliptype, :validate => [ "stream", "private" ], :required => true

  # The Stream name / Private address
  config :to, :validate => :string, :required => true

  # The Stream subject. This is not used when `zuliptype` is "private"
  config :subject, :validate => :string, :required => false

  # Message format to send, event tokens are usable here.
  config :format, :validate => :string, :default => "%{message}"

  public
  def register
    require 'net/https'
    require "uri"


    @url = "https://api.zulip.com/v1/messages"
    
    @zul_uri = URI.parse(@url)
    @client = Net::HTTP.new(@zul_uri.host, @zul_uri.port)
    if @zul_uri.scheme == "https"
      @client.use_ssl = true
    end
    
  end # def register

  public
  def receive(event)
    return unless output?(event)

    @logger.info("Zulip message", :zulip_message => event.sprintf(@format))

    begin
      request = Net::HTTP::Post.new(@zul_uri.path)
      request.basic_auth(@user, @password.value)
      request.add_field("User-Agent", "ZulipLogstash/0.1")
      
      if @zuliptype == 'stream'
        request.set_form_data({'type' => 'stream', 'to' => @to, 'subject' => @subject, 'content' =>  event.sprintf(@format)})
      elsif @zuliptype == 'private'
        request.set_form_data({'type' => 'private', 'to' => @to ,'content' =>  event.sprintf(@format)})
      end
      
      @logger.debug("Zulip Request", :request => request.inspect)
      response = @client.request(request)
      @logger.debug("Zulip Response", :response => response.body)
    rescue Exception => e
      @logger.debug("Zulip Unhandled exception", :error => e, :backtrace => e.backtrace)
    end
  end # def receive
end # class LogStash::Outputs::Zulip
