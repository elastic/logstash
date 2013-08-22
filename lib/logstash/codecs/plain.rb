require "logstash/codecs/base"

# This is the base class for logstash codecs.
class LogStash::Codecs::Plain < LogStash::Codecs::Base
  config_name "plain"
  milestone 3

  # Set the desired text format for encoding.
  #
  # This setting only affects encoding.
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
  def decode(data)
    data.force_encoding(@charset)
    if @charset != "UTF-8"
      # The user has declared the character encoding of this data is
      # something other than UTF-8. Let's convert it (as cleanly as possible)
      # into UTF-8 so we can use it with JSON, etc.
      data = data.encode("UTF-8", :invalid => :replace, :undef => :replace)
    end
    yield LogStash::Event.new({"message" => data})
  end # def decode

  public
  def encode(data)
    if data.is_a? LogStash::Event and @format
      @on_event.call(data.sprintf(@format))
    else
      @on_event.call(data.to_s)
    end
  end # def encode

end # class LogStash::Codecs::Plain
