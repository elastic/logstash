require "logstash/codecs/base"

class LogStash::Codecs::Noop < LogStash::Codecs::Base
  public
  def decode(data)
    yield data
  end # def decode

  public
  def encode(data)
    @on_event.call data
  end # def encode

end # class LogStash::Codecs::Noop
