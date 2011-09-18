require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash"
require "logstash/filters"
require "logstash/filters/grep"
require "logstash/event"

describe LogStash::Filters::Grep do
  before do
    @filter = LogStash::Filters.from_name("grep", {})
    @typename = "grepper"
  end

  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = [cfg[key]]
      end
    end

    @filter = LogStash::Filters::Grep.new(cfg)
    @filter.register
  end # def config

  test "single grep match" do
    config "str" => "test"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test: this should not be dropped"
    @filter.filter(event)
    assert_equal(false, event.cancelled?)
  end # testing a single match

  test "single match failure does not cancel the event with drop set to false" do
    config "str"  => "test",
           "drop" => "false"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "foo: this should be dropped"
    @filter.filter(event)
    assert_equal(false, event.cancelled?)
  end

  test "single match failure cancels the event" do
    config "str" => "test"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "foo: this should be dropped"
    @filter.filter(event)
    assert_equal(true, event.cancelled?)
  end

  test "multiple match conditions" do
    config "str" => "test", "bar" => "baz"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test: this should not be dropped"
    event["bar"] = "foo baz foo"
    @filter.filter(event)
    assert_equal(false, event.cancelled?)
  end # test_multiple_match

  test "multiple match conditions should cancel on failure" do
    config "str" => "test", "bar" => "baz"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test: this should be dropped"
    event["bar"] = "foo bAz foo"
    @filter.filter(event)
    assert_equal(true, event.cancelled?)
  end # test_multiple_match_drop

  test "single condition with regexp syntax" do
    config "str" => "(?i)test.*foo"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "TeST regexp match FoO"
    @filter.filter(event)
    assert_equal(false, event.cancelled?)
  end

  test "single condition with regexp syntax cancels on failure" do
    config "str" => "test.*foo"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "TeST regexp match FoO"
    @filter.filter(event)
    assert_equal(true, event.cancelled?)
  end # def test_single_match_regexp_drop

  test "adding fields on success" do
    config "str" => "test",
           "add_field" => ["new_field", "new_value"]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["new_value"], event["new_field"])
  end # def test_add_fields

  test "adding fields with a sprintf value" do
    config "str" => "test",
           "add_field" => ["new_field", "%{@type}"]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal([event.type], event["new_field"])
  end # def test_add_fields_with_format

  def __DISABLED_FOR_NOW_test_add_fields_multiple_match
    #config "match" => {"str" => "test"},
           #"add_fields" => {"new_field" => "new_value"}},
           #"match" => {"str" => ".*"},
             #"add_fields" => {"new_field" => "new_value_2"}},
           #]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["new_value", "new_value_2"], event["new_field"])
  end # def test_add_fields_multiple_match

  test "add tags" do
    config "str" => "test",
           "add_tag" => ["new_tag"]

    event = LogStash::Event.new
    event.tags << "tag"
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["tag", "new_tag"], event.tags)
  end # def test_add_tags

  test "add tags with drop set to false tags matching events" do
    config "str" => "test",
           "drop" => "false",
           "add_tag" => ["new_tag"]

    event = LogStash::Event.new
    event.tags << "tag"
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["tag", "new_tag"], event.tags)
    assert_equal(false, event.cancelled?)
  end # def test_add_tags

  test "add tags with drop set to false allows non-matching events through" do
    config "str" => "test",
           "drop" => "false",
           "add_tag" => ["new_tag"]

    event = LogStash::Event.new
    event.tags << "tag"
    event.type = @typename
    event["str"] = "non-matching"
    @filter.filter(event)
    assert_equal(["tag"], event.tags)
    assert_equal(false, event.cancelled?)
  end # def test_add_tags

  test "add tags with sprintf value" do
    config "str" => "test",
           "add_tag" => ["%{str}"]

    event = LogStash::Event.new
    event.tags << "tag"
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["tag", event["str"]], event.tags)
  end # def test_add_tags
end # TestFilterGrep
