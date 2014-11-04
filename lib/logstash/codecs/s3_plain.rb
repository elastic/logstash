# encoding: utf-8
require "logstash/codecs/base"
require "logstash/util/charset"

# The "s3_plain" codec is used for backward compatibility with previous version of the S3 Output
#
class LogStash::Codecs::S3Plain < LogStash::Codecs::Base
  config_name "s3_plain"
  milestone 3

  public
  def decode(data)
    raise RuntimeError.new("This codec is only used for backward compatibility with the previous S3 output.")
  end # def decode

  public
  def encode(event)
    if event.is_a?(LogStash::Event)

      message = "Date: #{event[LogStash::Event::TIMESTAMP]}\n"
      message << "Source: #{event["source"]}\n"
      message << "Tags: #{Array(event["tags"]).join(', ')}\n"
      message << "Fields: #{event.to_hash.inspect}\n"
      message << "Message: #{event["message"]}"

      @on_event.call(message)
    else
      @on_event.call(event.to_s)
    end
  end # def encode
end # class LogStash::Codecs::S3Plain
