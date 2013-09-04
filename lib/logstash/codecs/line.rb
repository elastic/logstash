require "logstash/codecs/base"

# Line-oriented text data.
#
# Decoding behavior: Only whole line events will be emitted.
#
# Encoding behavior: Each event will be emitted with a trailing newline.
class LogStash::Codecs::Line < LogStash::Codecs::Base
  config_name "line"
  milestone 3

  # Set the desired text format for encoding.
  config :format, :validate => :string

  # The character encoding used in this input. Examples include "UTF-8"
  # and "cp1252"
  #
  # This setting is useful if your log files are in Latin-1 (aka cp1252)
  # or in another character set other than UTF-8.
  #
  # This only affects "plain" format logs since json is UTF-8 already.
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  public
  def register
    require "logstash/util/buftok"
    @buffer = FileWatch::BufferedTokenizer.new
  end
  
  public
  def decode(data)
    @buffer.extract(data).each do |line|
      line.force_encoding(@charset)
      if @charset != "UTF-8"
        # The user has declared the character encoding of this data is
        # something other than UTF-8. Let's convert it (as cleanly as possible)
        # into UTF-8 so we can use it with JSON, etc.

        # To convert, we first tell ruby the string is *really* encoded as
        # somethign else (@charset), then we convert it to UTF-8.
        data = data.encode("UTF-8", :invalid => :replace, :undef => :replace)
      end
      yield LogStash::Event.new({"message" => line})
    end
  end # def decode

  public
  def flush(&block)
    remainder = @buffer.flush
    if !remainder.empty?
      block.call(LogStash::Event.new({"message" => remainder}))
    end
  end

  public
  def encode(data)
    if data.is_a? LogStash::Event and @format
      @on_event.call(data.sprintf(@format) + "\n")
    else
      @on_event.call(data.to_s + "\n")
    end
  end # def encode

end # class LogStash::Codecs::Plain
