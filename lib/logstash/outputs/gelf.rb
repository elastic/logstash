# GELF output
# http://www.graylog2.org/about/gelf
#
# This class doesn't currently use 'eventmachine'-style code, so it may
# block things. Whatever, we can fix that later ;)

require "gelf" # rubygem 'gelf'
require "logstash/namespace"
require "logstash/outputs/base"

class LogStash::Outputs::Gelf < LogStash::Outputs::Base
  
  public
  def initialize(url, config={}, &block)
    super

    @chunksize = @urlopts["chunksize"].to_i || 1420
    @level = @urlopts["level"] || 1
    @facility = @urlopts["facility"] || 'logstash-gelf'
    
  end

  public
  def register
    option_hash = Hash.new
    option_hash["level"] = @level
    option_hash["facility"] = @facility

    @gelf = GELF::Notifier.new(@url.host, (@url.port or 12201), @chunksize, option_hash)
  end # def register

  public
  def receive(event)
    m = Hash.new
    m["short_message"] = (event.fields["message"] or event.message)
    m["full_message"] = (event.message)
    m["host"] = event["@source_host"]
    m["file"] = event["@source_path"]
    m["level"] = 1

    event.fields.each do |name, value|
      next if value == nil or value.empty?
      m["#{name}"] = value
    end
    m["timestamp"] = event.timestamp
    @gelf.notify(m)
  end # def receive
end # class LogStash::Outputs::Gelf
