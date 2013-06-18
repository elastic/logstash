require "logstash/codecs/base"
require "json"

# This is the base class for logstash codecs.
class LogStash::Codecs::Json < LogStash::Codecs::Base
  config_name "json"

  milestone 1

  public
  def decode(data)
    yield LogStash::Event.new(JSON.parse(data.force_encoding("UTF-8")))
  end # def decode

  public
  def encode(data)
    @on_event.call data.to_json
  end # def encode

end # class LogStash::Codecs::Json
