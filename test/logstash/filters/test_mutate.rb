require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash"
require "logstash/filters"
require "logstash/filters/mutate"
require "logstash/event"

describe LogStash::Filters::Mutate do
  before do
    @filter = LogStash::Filters.from_name("mutate", {})
    @typename = "mutator"
  end

  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = [cfg[key]]
      end
    end

    @filter = LogStash::Filters::Mutate.new(cfg)
    @filter.register
  end # def config

  test "replace field value with plain string" do
    config "replace" => [ "foo", "bar" ]

    event = LogStash::Event.new
    event.type = @typename
    event["foo"] = "this will be replaced"
    @filter.filter(event)
    assert_equal(event["foo"], "bar")
  end # replace field value with plain string

  test "replace field value with sprintf string" do
    config "replace" => [ "foo", "hello %{world}" ]

    event = LogStash::Event.new
    event.type = @typename
    event["world"] = "earth"
    event["foo"] = "this will be replaced"
    @filter.filter(event)
    assert_equal(event["foo"], "hello earth")
  end # replace field value with sprintf string

  test "remove field" do
    config "remove" => [ "remove-me" ]

    event = LogStash::Event.new
    event.type = @typename
    event["remove-me"] = "Goodbye!"
    event["foo"] = "Hello."
    @filter.filter(event)
    assert_equal(event["foo"], "Hello.")
    assert(!event.include?("remove-me"),
           "The 'remove-me' field should have been removed, it was not.")
  end # replace field value with sprintf string

  test "remove multiple fields " do
    config "remove" => [ "remove-me", "remove-me2", "diedie" ]

    event = LogStash::Event.new
    event.type = @typename
    event["remove-me"] = "Goodbye!"
    event["remove-me2"] = 1234
    event["diedie"] = [1,2,3,4]
    event["foo"] = "Hello."
    @filter.filter(event)
    assert_equal(event["foo"], "Hello.")
    assert(!event.include?("remove-me"),
           "The 'remove-me' field should have been removed, it was not.")
    assert(!event.include?("remove-me2"),
           "The 'remove-me2' field should have been removed, it was not.")
    assert(!event.include?("diedie"),
           "The 'diedie' field should have been removed, it was not.")
  end # remove multiple fields

  test "rename one field" do
    config "rename" => [ "oldname", "newname" ]

    event = LogStash::Event.new
    event.type = @typename
    event["oldname"] = "whoa"
    event["foo"] = "Hello."

    @filter.filter(event)
    assert_equal(event["foo"], "Hello.")

    assert(!event.include?("oldname"),
           "The 'oldname' field should have been removed, it was not.")
    assert_equal(event["newname"], "whoa",
                 "The 'newname' field was not renamed properly?")
  end # rename one field

  test "convert one field to integer" do
    config "convert" => [ "foo", "integer" ]

    event = LogStash::Event.new
    event.type = @typename
    event["foo"] = "1234"

    @filter.filter(event)
    assert_equal(1234, event["foo"],
                 "Field 'foo' should now be an integer (1234), but is " \
                 " a #{event["foo"].class.inspect} (#{event["foo"].inspect})")
  end # convert one field

  test "convert one field to string" do
    config "convert" => [ "foo", "string" ]

    event = LogStash::Event.new
    event.type = @typename
    event["foo"] = 1234

    @filter.filter(event)
    assert_equal("1234", event["foo"],
                 "Field 'foo' should now be a string ('1234'), but is " \
                 " a #{event["foo"].class.inspect} (#{event["foo"].inspect})")
  end # convert one field

  test "convert one field to float" do
    config "convert" => [ "foo", "float" ]

    event = LogStash::Event.new
    event.type = @typename
    event["foo"] = "1234.10"

    @filter.filter(event)
    assert_equal(1234.10, event["foo"],
                 "Field 'foo' should now be an float (1234.10), but is " \
                 " a #{event["foo"].class.inspect} (#{event["foo"].inspect})")
  end # convert one field
end # Test 'mutate' filter
