require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"

require "test/unit"
require "logstash/loadlibs"
require "logstash"
require "logstash/filters"
require "logstash/filters/grep"
require "logstash/event"

class TestFilterGrep < Test::Unit::TestCase
  def setup
    @filter = LogStash::Filters.from_name("grep", {})
  end # def setup

  def test_name(name)
    @typename = name
  end # def test_name

  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = cfg[key].to_a
      end
    end

    @filter = LogStash::Filters::Grep.new(cfg)
    @filter.register
  end # def config

  def test_single_match
    test_name "single_match"
    config "str" => "test"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test: this should not be dropped"
    @filter.filter(event)
    assert_equal(false, event.cancelled?)
  end # def test_single_match

  def test_single_match_drop
    test_name "single_match_dropp"
    config "str" => "test"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "foo: this should be dropped"
    @filter.filter(event)
    assert_equal(true, event.cancelled?)
  end # def test_single_match_drop

  def test_multiple_match
    test_name "multiple_match"
    config "str" => "test", "bar" => "baz"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test: this should not be dropped"
    event["bar"] = "foo baz foo"
    @filter.filter(event)
    assert_equal(false, event.cancelled?)
  end # test_multiple_match

  def test_multiple_match_drop
    test_name "multiple_match_drop"
    config "str" => "test", "bar" => "baz"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test: this should be dropped"
    event["bar"] = "foo bAz foo"
    @filter.filter(event)
    assert_equal(true, event.cancelled?)
  end # test_multiple_match_drop

  def test_single_match_regexp
    test_name "single_match_regexp"
    config "str" => "(?i)test.*foo"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "TeST regexp match FoO"
    @filter.filter(event)
    assert_equal(false, event.cancelled?)
  end # def test_single_match_regexp

  def test_single_match_regexp_drop
    test_name "single_match_regexp_drop"
    config "str" => "test.*foo"

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "TeST regexp match FoO"
    @filter.filter(event)
    assert_equal(true, event.cancelled?)
  end # def test_single_match_regexp_drop

  def test_add_fields
    test_name "add_field"
    config "str" => "test",
           "add_field" => ["new_field", "new_value"]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["new_value"], event["new_field"])
  end # def test_add_fields

  def test_add_fields_with_format
    test_name "add_field_with_format"
    config "str" => "test",
           "add_field" => ["new_field", "%{@type}"]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal([event.type], event["new_field"])
  end # def test_add_fields_with_format

  def __DISABLED_FOR_NOW_test_add_fields_multiple_match
    test_name "add_fields_multiple_match"
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

  def test_add_tags
    test_name "add_tags"
    config "str" => "test",
           "add_tag" => ["new_tag"]

    event = LogStash::Event.new
    event.tags << "tag"
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["tag", "new_tag"], event.tags)
  end # def test_add_tags

  def test_add_tags_with_format
    test_name "add_tags_with_format"
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
