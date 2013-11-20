# encoding: utf-8
require "logstash/codecs/base"

class LogStash::Codecs::Dots < LogStash::Codecs::Base
  config_name "dots"
  milestone 1

  public
  def decode(data)
    raise "Not implemented"
  end # def decode

  public
  def encode(data)
    @on_event.call(".")
  end # def encode

end # class LogStash::Codecs::Dots
