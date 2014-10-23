# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/plain"
require "logstash/json"

# This codec will read gzip encoded content
class LogStash::Codecs::GzipLines < LogStash::Codecs::Base
  config_name "gzip_lines"

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
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
  end

  public
  def decode(data)
    @decoder = Zlib::GzipReader.new(data)

    begin
      @decoder.each_line do |line|
        yield LogStash::Event.new("message" => @converter.convert(line))
      end
    rescue Zlib::Error, Zlib::GzipFile::Error=> e
      file = data.is_a?(String) ? data : data.class

      @logger.error("Gzip codec: We cannot uncompress the gzip file", :filename => file)
      raise e
    end
  end # def decode
end # class LogStash::Codecs::GzipLines
