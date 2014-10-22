# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/plain"
require "logstash/json"

# This codec will read gzip encoded content
class LogStash::Codecs::Cloudfront < LogStash::Codecs::Base
  config_name "cloudfront"

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
    yield LogStash::Event.new("message" => @converter.convert(data))
  end

  public
  def decode(data)
    @gzip = Zlib::GzipReader.new(data)

    metadata = extract_metadata(@gzip)

    @gzip.each_line do |line|
      yield LogStash::Event.new("message" => @converter.convert(line), :metadata => metadata)
    end
  end # def decode

  public
  def extract_metadata(gzip)
    version = extract_version(gzip.gets)
    fields = extract_format(gzip.gets)

    return {
      :version => version,
      :format => fields,
      :cloudfront_version => version,
      :cloudfront_fields => fields,
    }
  end

  def extract_version(line)
    if /#Version: .+/.match(line)
      junk, version = line.strip().split(/#Version: (.+)/)
      unless version.nil?
        version
      end
    end
  end

  def extract_fields(line)
    if /#Fields: .+/.match(line)
      junk, format = line.strip().split(/#Fields: (.+)/)
      unless format.nil?
        format
      end
    end
  end
end # class LogStash::Codecs::JSON

# def process_line(queue, metadata, line)
#
#   if /#Version: .+/.match(line)
#     junk, version = line.strip().split(/#Version: (.+)/)
#     unless version.nil?
#       metadata[:version] = version
#     end
#   elsif /#Fields: .+/.match(line)
#     junk, format = line.strip().split(/#Fields: (.+)/)
#     unless format.nil?
#       metadata[:format] = format
#     end
#   else
#     @codec.decode(line) do |event|
#       decorate(event)
#       unless metadata[:version].nil?
#         event["cloudfront_version"] = metadata[:version]
#       end
#       unless metadata[:format].nil?
#         event["cloudfront_fields"] = metadata[:format]
#       end
#       queue << event
#     end
#   end
#   return metadata
#
# end # def process_line
