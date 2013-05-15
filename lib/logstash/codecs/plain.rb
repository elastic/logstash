require "logstash/codecs/base"

# This is the base class for logstash codecs.
class LogStash::Codecs::Plain < LogStash::Codecs::Base
  public
  def decode(data, opts = {})
    data.force_encoding(@charset)
    if @charset != "UTF-8"
      # Convert to UTF-8 if not in that character set.
      data = data.encode("UTF-8", :invalid => :replace, :undef => :replace)
    end
    @queue << LogStash::Event.new(opts.merge({"message" => data}))
  end # def decode

  public
  def encode(event)
    event.to_s
  end # def encode

  public
  def on_event(&block)
    @on_event = block
  end

end # class LogStash::Codecs::Plain
