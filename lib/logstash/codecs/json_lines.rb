# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/line"
require "json"

# This codec will decode streamed JSON that is newline delimited.
# For decoding line-oriented JSON payload in the redis or file inputs,
# for example, use the json codec instead.
# Encoding will emit a single JSON string ending in a '\n'
class LogStash::Codecs::JSONLines < LogStash::Codecs::Base
  config_name "json_lines"

  milestone 3

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
  def initialize(params={})
    super(params)
    @lines = LogStash::Codecs::Line.new
    @lines.charset = @charset
  end
  
  public
  def decode(data)

    @lines.decode(data) do |event|
      begin
        yield LogStash::Event.new(JSON.parse(event["message"]))
      rescue JSON::ParserError => e
        @logger.info("JSON parse failure. Falling back to plain-text", :error => e, :data => data)
        yield LogStash::Event.new("message" => event["message"])
      end
    end
  end # def decode

  public
  def encode(data)
    # Tack on a \n for now because previously most of logstash's JSON
    # outputs emitted one per line, and whitespace is OK in json.
    @on_event.call(data.to_json + "\n")
  end # def encode

end # class LogStash::Codecs::JSON
