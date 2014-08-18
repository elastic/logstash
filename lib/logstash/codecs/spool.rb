# encoding: utf-8
require "logstash/codecs/base"

class LogStash::Codecs::Spool < LogStash::Codecs::Base
  config_name 'spool'
  milestone 1
  config :spool_size, :validate => :number, :default => 50

  attr_reader :buffer

  public
  def decode(data)
    data.each do |event|
      yield event
    end
  end # def decode

  public
  def encode(event)
    @buffer ||= []
    #buffer size is hard coded for now until a
    #better way to pass args into codecs is implemented
    if @buffer.length >= @spool_size
      @on_event.call @buffer
      @buffer = []
    else
      @buffer << event
    end
  end # def encode

  public
  def teardown
    if !@buffer.nil? and @buffer.length > 0
      @on_event.call @buffer
    end
    @buffer = []
  end
end # class LogStash::Codecs::Spool
