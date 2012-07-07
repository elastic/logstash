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

  test "sprintf should not error when a token does not exist" do
    assert_equal("%{foo}", @event.sprintf("%{foo}"))
    assert_equal("%{foo.bar}", @event.sprintf("%{foo.bar}"))
  end

  test "sprintf should look inside hashes" do
    @event.fields["foo"] = {"bar" => "a", "baz" => "b"}
    assert_equal(@event.fields["foo"]["bar"], @event.sprintf("%{foo.bar}"))
    assert_equal(@event.fields["foo"]["baz"], @event.sprintf("%{foo.baz}"))
  end

  test "sprintf should be able to look >1 hash deep" do
    @event.fields["foo"] = {"bar" => {"baz" => "a"}}
    assert_equal(@event.fields["foo"]["bar"]["baz"],
                 @event.sprintf("%{foo.bar.baz}"))
  end

  test "sprintf should handle a failed hash lookup on a non-hash" do
    @event.fields["foo"] = "test"
    assert_equal("%{foo.bar}", @event.sprintf("%{foo.bar}"))
  end

  test "sprintf should find top-level keys with '.' if no data structure exists" do
    @event.fields["foo.bar"] = "test"
    assert_equal(@event.fields["foo.bar"], @event.sprintf("%{foo.bar}"))
  end
end # describe LogStash::Event
