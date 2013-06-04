require "logstash/codecs/base"

class LogStash::Codecs::None < LogStash::Codecs::Base
  public
  def decode(data, opts = {})
    @queue << data
  end # def decode

  public
  def encode(data)
    @on_event.call data
  end # def encode

end # class LogStash::Codecs::None
