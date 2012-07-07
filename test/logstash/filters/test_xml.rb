require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash"
require "logstash/filters"
require "logstash/filters/xml"
require "logstash/event"

describe LogStash::Filters::Xml do
  before do
    @filter = LogStash::Filters.from_name("xml", {})
    @typename = "xml"
  end

  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = [cfg[key]]
      end
    end

    @filter = LogStash::Filters::Xml.new(cfg)
    @filter.register
  end # def config

  test "parse standard xml" do
    config "raw" => "data"

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = '<foo key="value"/>'
    @filter.filter(event)
    assert_equal(event["data"], {"key" => "value"})
  end # parse standard xml

  test "parse xml but do not store" do
    config "raw" => "data",
           "store_xml" => "false"

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = '<foo key="value"/>'
    @filter.filter(event)
    assert_equal(event["data"], nil)
  end # parse xml but do not store

  test "parse xml with array as a value" do
    config "raw" => "data"

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = '<foo><key>value1</key><key>value2</key></foo>'
    @filter.filter(event)
    assert_equal(event["data"], {"key" => ["value1", "value2"]})
  end # parse xml with array as a value

  test "parse xml with hash as a value" do
    config "raw" => "data"

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = '<foo><key1><key2>value</key2></key1></foo>'
    @filter.filter(event)
    assert_equal(event["data"], {"key1" => [{"key2" => ["value"]}]})
  end # parse xml with array as a value

  test "bad xml" do
    config "raw" => "data"

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = '<foo /'
    @filter.filter(event)
    assert_equal(event.tags, ["_xmlparsefailure"])
  end # bad xml

  test "parse xml and store single value with xpath" do
    config "raw" => "data",
           "xpath" => [ "/foo/key/text()", "xpath_field" ]

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = '<foo><key>value</key></foo>'
    @filter.filter(event)
    assert_equal(event["xpath_field"].length, 1)
    assert_equal(event["xpath_field"], ["value"])
  end # parse xml and store single value with xpath

  test "parse xml and store mulitple values with xpath" do
    config "raw" => "data",
           "xpath" => [ "/foo/key/text()", "xpath_field" ]

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = '<foo><key>value1</key><key>value2</key></foo>'
    @filter.filter(event)
    assert_equal(event["xpath_field"].length, 2)
    assert_equal(event["xpath_field"], ["value1","value2"])
  end # parse xml and store mulitple values with xpath

end # Test 'xml' filter
