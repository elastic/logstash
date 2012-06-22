require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash"
require "logstash/filters"
require "logstash/filters/syslog_pri"
require "logstash/event"

describe LogStash::Filters::Syslog_pri do
  before do
    @filter = LogStash::Filters.from_name("syslog_pri", {})
    @typename = "syslog_pri"
  end

  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = [cfg[key]]
      end
    end

    @filter = LogStash::Filters::Syslog_pri.new(cfg)
    @filter.register
  end # def config

  test "severity" do
    event = LogStash::Event.new
    event.type = @typename
    event["syslog_pri"] = 75
    @filter.filter(event)
    assert_equal(3, event["syslog_severity_code"])
  end

  test "severity field name" do
    event = LogStash::Event.new
    event.type = @typename
    event["syslog_pri"] = 75
    @filter.filter(event)
    assert_equal("error", event["syslog_severity"])
  end

  test "facility" do
    event = LogStash::Event.new
    event.type = @typename
    event["syslog_pri"] = 75
    @filter.filter(event)
    assert_equal(9, event["syslog_facility_code"])
  end

  test "facility field name" do
    event = LogStash::Event.new
    event.type = @typename
    event["syslog_pri"] = 75
    @filter.filter(event)
    assert_equal("clock", event["syslog_facility"])
  end

  test "no field names added with use_labels=false" do
    config "use_labels" => "false"

    event = LogStash::Event.new
    event.type = @typename
    event["syslog_pri"] = 75
    @filter.filter(event)
    assert_equal(nil, event["syslog_facility"])
    assert_equal(nil, event["syslog_severity"])
  end

  test "default priority of 13" do
    event = LogStash::Event.new
    event.type = @typename
    @filter.filter(event)
    assert_equal(1, event["syslog_facility_code"])
    assert_equal(5, event["syslog_severity_code"])
  end

  test "priority as array" do
    event = LogStash::Event.new
    event.type = @typename
    event["syslog_pri"] = [75]
    @filter.filter(event)
    assert_equal(9, event["syslog_facility_code"])
    assert_equal(3, event["syslog_severity_code"])
  end

  test "set priority field name" do
    config "syslog_pri_field_name" => "syslog_pri2"

    event = LogStash::Event.new
    event.type = @typename
    event["syslog_pri"] = 15
    event["syslog_pri2"] = 75
    @filter.filter(event)
    assert_equal(9, event["syslog_facility_code"])
    assert_equal(3, event["syslog_severity_code"])
  end

  test "custom facility labels" do
    config "facility_labels" => ["a", "b", "c", "d", "e", "f"]

    event = LogStash::Event.new
    event.type = @typename
    @filter.filter(event)
    assert_equal("b", event["syslog_facility"])
  end

  test "custom severity labels" do
    config "severity_labels" => ["a", "b", "c", "d", "e", "f"]

    event = LogStash::Event.new
    event.type = @typename
    @filter.filter(event)
    assert_equal("f", event["syslog_severity"])
  end
end # Test 'syslog_pri' filter
