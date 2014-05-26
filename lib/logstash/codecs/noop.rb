# encoding: utf-8
require "logstash/codecs/base"

class LogStash::Codecs::Noop < LogStash::Codecs::Base
  config_name "noop"

  milestone 1

  public
  def decode(data)
    yield data
  end # def decode

  public
  def encode(event)
    @on_event.call event
  end # def encode

end # class LogStash::Codecs::Noop
