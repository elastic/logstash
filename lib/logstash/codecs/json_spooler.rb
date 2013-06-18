require "logstash/codecs/base"
require "logstash/codecs/spool"

# This is the base class for logstash codecs.
class LogStash::Codecs::JsonSpooler < LogStash::Codecs::Spool
  config_name "json_spooler"
  milestone 1

  public
  def decode(data)
    super(JSON.parse(data.force_encoding("UTF-8"))) do |event|
      yield event
    end
  end # def decode

  public
  def encode(data)
    super(data)
  end # def encode

end # class LogStash::Codecs::Json
