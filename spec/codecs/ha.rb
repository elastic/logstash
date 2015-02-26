# encoding: utf-8
require "test_utils"
require "logstash/codecs/ha"
require "logstash/event"

describe LogStash::Codecs::HA do
  it "Should handle bundles of 1" do
    codec = double("codec")
    ha_codec = LogStash::Codecs::HA.new(codec)
    event = LogStash::Event.new("sna" => "fu")

    callback = nil
    expect(codec).to receive(:on_event) do |&block|
      callback = block
    end
    expect(codec).to receive(:encode) do |event_received|
      insist { event_received } == event
      callback.call "Hello"
    end

    # monitor state changes
    actions = []
    event.on "filter_processed" do
      actions.push "filter_processed"
    end
    event.on "output_sent" do
      actions.push "output_sent"
    end

    message = nil
    ha_codec.on_event do |message_received|
      message = message_received
      true # <- returned
    end
    ha_codec.encode(event)

    insist { actions } == ["filter_processed"]
    event.trigger "output_send"

    insist { message } == "Hello"
    insist { actions } == ["filter_processed", "output_sent"]
  end

  it "Should handle bundles of multiple events" do
    codec = double("codec")
    ha_codec = LogStash::Codecs::HA.new(codec)
    event1 = LogStash::Event.new("fu" => "bar")
    event2 = LogStash::Event.new("sna" => "fu")
    event3 = LogStash::Event.new("Hello" => "World")

    callback = nil
    expect(codec).to receive(:on_event) do |&block|
      callback = block
    end
    expect(codec).to receive(:encode).with(event1)
    expect(codec).to receive(:encode).with(event2)
    expect(codec).to receive(:encode) do |event_received|
      insist { event_received } == event3
      callback.call "World"
    end

    # Handle state changes
    actions = []
    event1.on "filter_processed" do
      actions.push "filter_processed"
    end
    event2.on "filter_processed" do
      actions.push "filter_processed"
    end
    event3.on "filter_processed" do
      actions.push "filter_processed"
    end
    event1.on "output_sent" do
      actions.push "output_sent"
    end
    event2.on "output_sent" do
      actions.push "output_sent"
    end
    event3.on "output_sent" do
      actions.push "output_sent"
    end

    message = nil
    ha_codec.on_event do |message_received|
      message = message_received
      true # <- returned
    end
    ha_codec.encode(event1)
    ha_codec.encode(event2)
    ha_codec.encode(event3)

    insist { actions } == ["filter_processed", "filter_processed", "filter_processed"]

    insist { message } == nil
    insist { actions } == ["filter_processed", "filter_processed", "filter_processed"]
    event1.trigger "output_send"
    insist { message } == nil
    insist { actions } == ["filter_processed", "filter_processed", "filter_processed"]
    event2.trigger "output_send"
    insist { message } == nil
    insist { actions } == ["filter_processed", "filter_processed", "filter_processed"]
    event3.trigger "output_send"
    insist { message } == "World"

    insist { actions } == ["filter_processed", "filter_processed", "filter_processed",
                           "output_sent", "output_sent", "output_sent"]
  end

  it "should not trigger output_sent for messages that fail to be sent" do
    # todo(alcinnz): Should we specify that it resends or let the client resend?
    #   Here I'm letting client resend, but it might be better to have the server do it instead.
    codec = double("codec")
    ha_codec = LogStash::Codecs::HA.new(codec)
    event = LogStash::Event.new("sna" => "fu")

    callback = nil
    expect(codec).to receive(:on_event) do |&block|
      callback = block
    end
    expect(codec).to receive(:encode) do |event_received|
      insist { event_received } == event
      callback.call "Hello"
    end

    # monitor state changes
    actions = []
    event.on "filter_processed" do
      actions.push "filter_processed"
    end
    event.on "output_sent" do
      actions.push "output_sent"
    end

    message = nil
    ha_codec.on_event do |message_received|
      message = message_received
      false # <- returned
    end
    ha_codec.encode(event)

    insist { actions } == ["filter_processed"]
    event.trigger "output_send"

    insist { message } == "Hello"
    insist { actions } == ["filter_processed"]
  end
end
