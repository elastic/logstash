require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash"
require "logstash/filters"
require "logstash/filters/json"
require "logstash/event"

describe LogStash::Filters::Json do
  before do
    @filter = LogStash::Filters.from_name("json", {})
    @typename = "json"
  end

  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = [cfg[key]]
      end
    end

    @filter = LogStash::Filters::Json.new(cfg)
    @filter.register
  end # def config

  test "parse standard json" do
    config "raw" => "data"

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = '{"key": "value"}'
    @filter.filter(event)
    assert_equal(event["data"], {"key" => "value"})
  end # parse standard json

  test "parse json with array as a value" do
    config "raw" => "data"

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = '{"key": ["value1", "value2"]}'
    @filter.filter(event)
    assert_equal(event["data"], {"key" => ["value1", "value2"]})
  end # parse json with array as a value

  test "parse json with hash as a value" do
    config "raw" => "data"

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = '{"key1": {"key2": "value"}}'
    @filter.filter(event)
    assert_equal(event["data"], {"key1" => {"key2" => "value"}})
  end # parse json with array as a value

  test "bad json" do
    config "raw" => "data"

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = '{"key1": {"key2", "value"}'
    @filter.filter(event)
    assert_equal(event.tags, ["_jsonparsefailure"])
  end # bad json
end # Test 'json' filter
