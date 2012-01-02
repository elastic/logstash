require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash"
require "logstash/filters"
require "logstash/filters/gelfify"
require "logstash/event"

describe LogStash::Filters::Gelfify do
  before do
    @filter = LogStash::Filters.from_name("gelfify", {})
    @typename = "gelf"
  end

  def config(cfg = {})
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = [cfg[key]]
      end
    end

    @filter = LogStash::Filters::Gelfify.new(cfg)
    @filter.register
  end # def config

  test "gelfify, severity field" do
    config

    LogStash::Filters::Gelfify::SYSLOG_LEVEL_MAP.each do |old, new|
      event = LogStash::Event.new
      event.type = @typename
      event["severity"] = old.to_s
      @filter.filter(event)
      assert_equal(event["GELF_severity"], new)
    end
  end # gelfify, severity field

  test "gelfify, random severity field" do
    config

    event = LogStash::Event.new
    event.type = @typename
    event["severity"] = "xyz"
    @filter.filter(event)
    assert_equal(event["GELF_severity"], nil)
  end # gelfify, random severity field

  test "gelfify, missing severity field" do
    config

    event = LogStash::Event.new
    event.type = @typename
    @filter.filter(event)
    assert_equal(event["GELF_severity"], nil)
  end # gelfify, missing severity field
end # Test 'gelfify' filter
