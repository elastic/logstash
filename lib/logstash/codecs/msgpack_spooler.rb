# encoding: utf-8
require "logstash/codecs/base"

class LogStash::Codecs::MsgpackSpooler < LogStash::Codecs::Base
  config_name 'msgpack_spooler'
  milestone 1
  config :spool_size, :validate => :number, :default => 50

  public
  def register
    require "msgpack"
    @buffer = []
  end

  public
  def decode(data)
    data = MessagePack.unpack(data)
    data.each do |event|
      event = LogStash::Event.new(event)
      event["@timestamp"] = Time.at(event["@timestamp"]).utc if event["@timestamp"].is_a? Float
      yield event
    end
  end # def decode

  public
  def encode(data)
    if @buffer.length >= @spool_size
      @on_event.call MessagePack.pack(@buffer)
      @buffer.clear
    else
      data["@timestamp"] = data["@timestamp"].to_f
      @buffer << data.to_hash
    end
  end # def encode

  public
  def teardown
    puts "teardown"
    if !@buffer.nil? and @buffer.length > 0
      @on_event.call @buffer
    end
    @buffer.clear
  end
end # class LogStash::Codecs::CompressSpooler
