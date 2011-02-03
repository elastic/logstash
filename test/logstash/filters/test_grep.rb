require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"

require "test/unit"
require "logstash"
require "logstash/filters"
require "logstash/event"

class TestFilterGrep < Test::Unit::TestCase
  def setup
    @filter = LogStash::Filters.from_name("grep", {})
  end

  def test_name(name)
    @typename = name
  end

  def config(cfg)
    @filter.add_config(@typename, cfg)
    @filter.register
  end

  def test_single_match
    test_name "single_match"
    config [{"match" => {"str" => "test"}}]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test: this should not be dropped"
    @filter.filter(event)
    assert_equal(false, event.cancelled?)
  end # def test_single_match

  def test_single_match_drop
    test_name "single_match_dropp"
    config [{"match" => {"str" => "test"}}]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "foo: this should be dropped"
    @filter.filter(event)
    assert_equal(true, event.cancelled?)
  end # def test_single_match_drop

  def test_multiple_match
    test_name "multiple_match"
    config [{"match" => {"str" => "test", "bar" => "baz"}}]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test: this should not be dropped"
    event["bar"] = "foo baz foo"
    @filter.filter(event)
    assert_equal(false, event.cancelled?)
  end # test_multiple_match

  def test_multiple_match_drop
    test_name "multiple_match_drop"
    config [{"match" => {"str" => "test", "bar" => "baz"}}]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test: this should be dropped"
    event["bar"] = "foo bAz foo"
    @filter.filter(event)
    assert_equal(true, event.cancelled?)
  end # test_multiple_match_drop

  def test_single_match_regexp
    test_name "single_match_regexp"
    config [{"match" => {"str" => "(?i)test.*foo"}}]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "TeST regexp match FoO"
    @filter.filter(event)
    assert_equal(false, event.cancelled?)
  end # def test_single_match_regexp

  def test_single_match_regexp_drop
    test_name "single_match_regexp_drop"
    config [{"match" => {"str" => "test.*foo"}}]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "TeST regexp match FoO"
    @filter.filter(event)
    assert_equal(true, event.cancelled?)
  end # def test_single_match_regexp_drop

  def test_add_fields
    test_name "add_fields"
    config [{"match" => {"str" => "test"},
             "add_fields" => {"new_field" => "new_value"}},
           ]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["new_value"], event["new_field"])
  end # def test_add_fields

  def test_add_fields_with_format
    test_name "add_fields"
    config [{"match" => {"str" => "test"},
             "add_fields" => {"new_field" => "${@type}"}},
           ]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal([event.type], event["new_field"])
  end # def test_add_fields

  def test_add_fields_multiple_match
    test_name "add_fields_multiple_match"
    config [{"match" => {"str" => "test"},
             "add_fields" => {"new_field" => "new_value"}},
            {"match" => {"str" => ".*"},
             "add_fields" => {"new_field" => "new_value_2"}},
           ]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["new_value", "new_value_2"], event["new_field"])
  end # def test_add_fields_multiple_match

  def test_add_tags
    test_name "add_tags"
    config [{"match" => {"str" => "test"},
             "add_tags" => ["new_tag"]},
           ]

    event = LogStash::Event.new
    event.tags << "tag"
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["tag", "new_tag"], event.tags)
  end # def test_add_tags

  def test_add_tags_with_format
    test_name "add_tags"
    config [{"match" => {"str" => "test"},
             "add_tags" => ["${str}"]},
           ]

    event = LogStash::Event.new
    event.tags << "tag"
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["tag", event["str"]], event.tags)
  end # def test_add_tags
end # TestFilterGrep
