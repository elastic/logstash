require "logstash/codecs/base"

# This is the base class for logstash codecs.
class LogStash::Codecs::Plain < LogStash::Codecs::Base
  attr_accessor :format

  public
  def decode(data)
    data.force_encoding(@charset)
    if @charset != "UTF-8"
      # Convert to UTF-8 if not in that character set.
      data = data.encode("UTF-8", :invalid => :replace, :undef => :replace)
    end
    yield LogStash::Event.new({"message" => data})
  end # def decode

  public
  def encode(data)
    if data.is_a? LogStash::Event and !@format.nil?
      @on_event.call data.sprintf(@format)
    else
      @on_event.call data.to_s
    end
  end # def encode

end # class LogStash::Codecs::Plain
