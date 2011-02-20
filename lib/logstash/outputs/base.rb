require "cgi"
require "logstash/event"
require "logstash/logging"
require "logstash/namespace"
require "logstash/config/mixin"
require "uri"

class LogStash::Outputs::Base
  include LogStash::Config::Mixin

  attr_accessor :logger

  config_name "outputs"
  dsl_parent nil

  public
  def initialize(url)
    @url = url
    @url = URI.parse(url) if url.is_a? String
    @logger = LogStash::Logger.new(STDOUT)
    @urlopts = {}
    if @url.query
      @urlopts = CGI.parse(@url.query)
      @urlopts.each do |k, v|
        @urlopts[k] = v.last if v.is_a?(Array)
      end
    end
  end

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def receive(event)
    raise "#{self.class}#receive must be overidden"
  end # def receive
end # class LogStash::Outputs::Base
