# encoding: utf-8
require "logstash/codecs/base"

class LogStash::Codecs::HA < LogStash::Codecs::Base
  public
  def initialize(codec)
    @codec = codec
    @bundle = []
  end

  def on_event(&on_event)
    @codec.on_event do |message|
      success = on_event.call message

      if success
        @bundle.each do |event|
          event.trigger "output_sent"
        end
      else
        # Nacks generally indicate an intent to clear the queue,
        # So get the client to resend by not acking.
      end
      @bundle.clear
    end
  end

  def encode(event)
    event.on "output_send" do
      @codec.encode(event)
    end

    @bundle.push event

    event.trigger "filter_processed"
  end

  def flush(&block)
    @codec.flush(&block)
  end
end
