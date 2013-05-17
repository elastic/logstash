require "logstash/codecs/base"
require "json"

# This is the base class for logstash codecs.
class LogStash::Codecs::Json < LogStash::Codecs::Base
  public
  def decode(data, opts = {})
    @queue << LogStash::Event.new(opts.merge(JSON.parse(data.force_encoding("UTF-8"))))
  end # def decode

  public
  def encode(event)
    @on_event.call event.to_json
  end # def encode

end # class LogStash::Codecs::Json
