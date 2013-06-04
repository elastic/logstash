require "logstash/codecs/base"

class LogStash::Codecs::Spool < LogStash::Codecs::Base

  attr_reader :buffer

  public
  def decode(data, opts = {})
    data.each do |event|
      @queue << event
    end
  end # def decode

  public
  def encode(data)
    @buffer = [] if @buffer.nil?
    #buffer size is hard coded for now until a 
    #better way to pass args into codecs is implemented
    if @buffer.length >= 50
      @on_event.call @buffer
      @buffer = []
    else
      @buffer << data
    end
  end # def encode

end # class LogStash::Codecs::Spool
