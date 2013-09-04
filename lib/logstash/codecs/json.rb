require "logstash/codecs/base"
require "json"

# This codec will encode and decode JSON.
class LogStash::Codecs::Json < LogStash::Codecs::Base
  config_name "json"

  milestone 1

  # The character encoding used in this codec. Examples include "UTF-8" and
  # "CP1252"
  #
  # JSON requires valid UTF-8 strings, but in some cases, software that
  # emits JSON does so in another encoding (nxlog, for example). In
  # weird cases like this, you can set the charset setting to the
  # actual encoding of the text and logstash will convert it for you.
  #
  # For nxlog users, you'll want to set this to "CP1252"
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

    begin
      yield LogStash::Event.new(JSON.parse(data))
    rescue JSON::ParserError => e
      @logger.info("JSON parse failure. Falling back to plain-text", :error => e, :data => data)
      yield LogStash::Event.new("message" => data)
    end
  end # def decode

  public
  def encode(data)
    # Tack on a \n for now because previously most of logstash's JSON
    # outputs emitted one per line, and whitespace is OK in json.
    @on_event.call(data.to_json + "\n")
  end # def encode

end # class LogStash::Codecs::Json
