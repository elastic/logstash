# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/spool"

# This is the base class for logstash codecs.
class LogStash::Codecs::JsonSpooler < LogStash::Codecs::Spool
  config_name "json_spooler"
  milestone 0

  public
  def register
    @logger.error("the json_spooler codec is deprecated and will be removed in a future release")
  end

  public
  def decode(data)
    super(JSON.parse(data.force_encoding(Encoding::UTF_8))) do |event|
      yield event
    end
  end # def decode

  public
  def encode(data)
    super(data)
  end # def encode

end # class LogStash::Codecs::Json
