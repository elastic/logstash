# encoding: utf-8

require "spec_helper"
require "jruby-mmap-queues"
require "logstash/queue_serializer"
require "logstash/event"

QUEUE_PATH = "persistent_queue_spec"

describe "persistent queue" do
  it "should push a serialized event and reload a deserialized event" do
    q = Mmap::SizedQueue.new(QUEUE_PATH, 20,
      :page_handler => Mmap::SinglePage.new(QUEUE_PATH, :page_size => 1024 * 1024),
      :serializer => LogStash::JsonSerializer.new
    )
    q.clear

    event = LogStash::Event.new({"foo" => "bar", "@metadata" => {"baz" => "zoo"}})
    expect(event["foo"]).to eq("bar")
    expect(event.metadata).to eq({"baz" => "zoo"})

    q.push(event)
    q.close

    # queue has been closed with one event in it, repopening on the same data will
    # feed queue with persisted items

    q = Mmap::SizedQueue.new(QUEUE_PATH, 20,
      :page_handler => Mmap::SinglePage.new(QUEUE_PATH, :page_size => 1024 * 1024),
      :serializer => LogStash::JsonSerializer.new
    )

    event = q.pop
    expect(event["foo"]).to eq("bar")
    expect(event.metadata).to eq({"baz" => "zoo"})

    expect(q.empty?).to be true
  end
end
