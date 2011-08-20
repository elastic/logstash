require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../lib"
$:.unshift File.dirname(__FILE__) + "/../"

require "minitest/spec"
require "logstash"
require "logstash/event"

describe LogStash::Event do
  before do
    @event = LogStash::Event.new
    @event.type = "sprintf"
    @event.message = "hello world"
    @event.source = "/home/foo"
  end

  it "must have a functional sprintf method" do
    @event["test"] = "test"
    ["@type", "@message", "@source", "test"].each do |name|
      assert_equal(@event[name], @event.sprintf("%{#{name}}"))
    end
  end

  it "on sprintf, join array fields by ','" do
    @event.fields["foo"] = ["one", "two", "three"]
    assert_equal(@event.fields["foo"].join(","), @event.sprintf("%{foo}"))
  end # sprintf testing
end # describe LogStash::Event
