# encoding: utf-8
require "logstash/codecs/base"
require "logstash/util/charset"
require "logstash/json"

# This codec may be used to decode (via inputs) and encode (via outputs)
# full JSON messages.  If you are streaming JSON messages delimited
# by '\n' then see the `json_lines` codec.
# Encoding will result in a single JSON string.
class LogStash::Codecs::JSON < LogStash::Codecs::Base
  config_name "json"

  milestone 3

  # The character encoding used in this codec. Examples include "UTF-8" and
  # "CP1252".
  #
  # JSON requires valid UTF-8 strings, but in some cases, software that
  # emits JSON does so in another encoding (nxlog, for example). In
  # weird cases like this, you can set the `charset` setting to the
  # actual encoding of the text and Logstash will convert it for you.
  #
  # For nxlog users, you'll want to set this to "CP1252".
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  public
  def register
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
  end

  public
  def decode(data)
    data = @converter.convert(data)
    begin
      yield LogStash::Event.new(LogStash::Json.load(data))
    rescue LogStash::Json::ParserError => e
      @logger.info("JSON parse failure. Falling back to plain-text", :error => e, :data => data)
      yield LogStash::Event.new("message" => data)
    end
  end # def decode

  public
  def encode(event)
    @on_event.call(event.to_json)
  end # def encode

end # class LogStash::Codecs::JSON
