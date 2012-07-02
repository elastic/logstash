require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash"
require "logstash/filters"
require "logstash/filters/csv"
require "logstash/event"

describe LogStash::Filters::Csv do
  before do
    @filter = LogStash::Filters.from_name("csv", {})
    @typename = "csv"
  end

  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = [cfg[key]]
      end
    end

    @filter = LogStash::Filters::Csv.new(cfg)
    @filter.register
  end # def config

  test "parse csv with field names" do
    config "raw" => "data",
           "fields" => ["custom1", "custom2", "custom3"]

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = "val1,val2,val3"
    @filter.filter(event)
    assert_equal({"custom1" => "val1",
                  "custom2" => "val2",
                  "custom3" => "val3"},
                 event["data"])
  end

  test "parse csv without field names" do
    config "raw" => "data"

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = "val1,val2,val3"
    @filter.filter(event)
    assert_equal({"field1" => "val1",
                  "field2" => "val2",
                  "field3" => "val3"},
                 event["data"])
  end

  test "parse csv with more data than defined field names" do
    config "raw" => "data",
           "fields" => ["custom1", "custom2"]

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = "val1,val2,val3"
    @filter.filter(event)
    assert_equal({"custom1" => "val1",
                  "custom2" => "val2",
                  "field3" => "val3"},
                 event["data"])
  end

  test "fail to parse any data in a multi-value field" do
    config "raw" => "data",
           "fields" => ["custom1", "custom2"]

    event = LogStash::Event.new
    event.type = @typename
    event["raw"] = ["val1,val2,val3", "val1,val2,val3"]
    @filter.filter(event)
    assert_equal(nil, event["data"])
  end
end # Test 'csv' filter
