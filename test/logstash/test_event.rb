require File.join(File.dirname(__FILE__), "minitest")
require "logstash/event"

describe LogStash::Event do
  before do
    @event = LogStash::Event.new
    @event.type = "sprintf"
    @event.message = "hello world"
    @event.source = "/home/foo"
  end

  test "sprintf method should work" do
    @event["test"] = "test"
    ["@type", "@message", "@source", "test"].each do |name|
      assert_equal(@event[name], @event.sprintf("%{#{name}}"))
      assert_equal("hello " + @event[name] + " world", 
                   @event.sprintf("hello %{#{name}} world"))
    end
  end

  test "sprintf should join array fields by comma" do
    @event.fields["foo"] = ["one", "two", "three"]
    assert_equal(@event.fields["foo"].join(","), @event.sprintf("%{foo}"))
  end # sprintf testing
end # describe LogStash::Event
