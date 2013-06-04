require "logstash/codecs/base"
require "logstash/codecs/spool"

# This is the base class for logstash codecs.
class LogStash::Codecs::JsonSpooler < LogStash::Codecs::Base
  public 
  def initialize
    @spooler = LogStash::Codecs::Spool.new
    @spooler.on_event do |data|
      @on_event.call data.to_json
    end
  end
  public
  def decode(data)
    @spooler.decode(JSON.parse(data.force_encoding("UTF-8"))) do |event|
      yield event
    end
  end # def decode

  public
  def encode(data)
    @spooler.encode(data)
  end # def encode

end # class LogStash::Codecs::Json
