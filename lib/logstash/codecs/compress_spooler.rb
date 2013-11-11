require "logstash/codecs/base"

class LogStash::Codecs::CompressSpooler < LogStash::Codecs::Base
  config_name 'compress_spooler'
  milestone 1
  config :spool_size, :validate => :number, :default => 50
  config :compress_level, :validate => :number, :default => 6

  public
  def register
    require "msgpack"
    require "zlib"
    @buffer = []
  end

  public
  def decode(data)
    z = Zlib::Inflate.new
    data = MessagePack.unpack(z.inflate(data))
    z.finish
    z.close
    data.each do |event|
      event = LogStash::Event.new(event)
      event["@timestamp"] = Time.at(event["@timestamp"]).utc if event["@timestamp"].is_a? Float
      yield event
    end
  end # def decode

  public
  def encode(data)
    if @buffer.length >= @spool_size
      z = Zlib::Deflate.new(@compress_level)
      @on_event.call z.deflate(MessagePack.pack(@buffer), Zlib::FINISH)
      z.close
      @buffer.clear
    else
      data["@timestamp"] = data["@timestamp"].to_f
      @buffer << data.to_hash
    end
  end # def encode

  public
  def teardown
    if !@buffer.nil? and @buffer.length > 0
      @on_event.call @buffer
    end
    @buffer.clear
  end
end # class LogStash::Codecs::CompressSpooler
