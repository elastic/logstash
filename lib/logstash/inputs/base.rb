require "logstash/namespace"
require "logstash/event"
require "logstash/logging"
require "logstash/config/mixin"
require "uri"

class LogStash::Inputs::Base
  include LogStash::Config::Mixin
  attr_accessor :logger

  config_name "input"

  # Define the basic config
  config "path" => :string #LogStash::Config::Path
  config "tag" => :string #LogStash::Config::Array

  public
  def initialize(configs, output_queue)
    @logger = LogStash::Logger.new(STDERR)
    @configs = configs
    @output_queue = output_queue
    #@url = url
    #@url = URI.parse(url) if url.is_a? String
    #@config = config
    #@callback = block
    #@type = type
    #@tags = []

    #@urlopts = {}
    #if @url.query
    #  @urlopts = CGI.parse(@url.query)
    #  @urlopts.each do |k, v|
    #    @urlopts[k] = v.last if v.is_a?(Array)
    #  end
    #end
  end # def initialize

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def tag(newtag)
    @tags << newtag
  end # def tag

  public
  def receive(event)
    @logger.debug(["Got event", { :url => @url, :event => event }])
    # Only override the type if it doesn't have one
    event.type = @type if !event.type 
    event.tags |= @tags # set union
    @callback.call(event)
  end # def receive
end # class LogStash::Inputs::Base
