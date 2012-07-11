require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash"
require "logstash/filters"
require "logstash/filters/noop"
require "logstash/event"

describe LogStash::Filters::NOOP do
  before do
    @typename = "noop"
  end

  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = [cfg[key]]
      end
    end

    @filter = LogStash::Filters::NOOP.new(cfg)
    @filter.register
  end # def config

  test "type parsing" do
    config "add_tag" => ["test"]

    event = LogStash::Event.new
    event.type = @typename
    @filter.filter(event)
    assert_equal(["test"], event.tags)

    event = LogStash::Event.new
    event.type = @typename + "_"
    @filter.filter(event)
    assert_equal([], event.tags)
  end

  test "tags parsing with one tag" do
    config "tags" => ["t1"],
           "add_tag" => ["test"]

    event = LogStash::Event.new
    event.type = @typename
    @filter.filter(event)
    assert_equal([], event.tags)

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t1", "t2"]
    @filter.filter(event)
    assert_equal(["t1", "t2", "test"], event.tags)
  end

  test "tags parsing with multiple tags" do
    config "tags" => ["t1", "t2"],
           "add_tag" => ["test"]

    event = LogStash::Event.new
    event.type = @typename
    @filter.filter(event)
    assert_equal([], event.tags)

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t1"]
    @filter.filter(event)
    assert_equal(["t1"], event.tags)

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t1", "t2"]
    @filter.filter(event)
    assert_equal(["t1", "t2", "test"], event.tags)

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t1", "t2", "t3"]
    @filter.filter(event)
    assert_equal(["t1", "t2", "t3", "test"], event.tags)
  end

  test "exclude_tags with 1 tag" do
    config "tags" => ["t1"],
           "add_tag" => ["test"],
           "exclude_tags" => ["t2"]

    event = LogStash::Event.new
    event.type = @typename
    event.tags = []
    @filter.filter(event)
    assert_equal([], event.tags)

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t1"]
    @filter.filter(event)
    assert_equal(["t1", "test"], event.tags)

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t1", "t2"]
    @filter.filter(event)
    assert_equal(["t1", "t2"], event.tags)
  end

  test "exclude_tags with >1 tag" do
    config "tags" => ["t1"],
           "add_tag" => ["test"],
           "exclude_tags" => ["t2", "t3"]

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t1", "t2", "t4"]
    @filter.filter(event)
    assert_equal(["t1", "t2", "t4"], event.tags)

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t1", "t3", "t4"]
    @filter.filter(event)
    assert_equal(["t1", "t3", "t4"], event.tags)

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t1", "t4", "t5"]
    @filter.filter(event)
    assert_equal(["t1", "t4", "t5", "test"], event.tags)
  end

  test "remove_tag" do
    config "tags" => ["t1"],
           "remove_tag" => ["t2", "t3"]

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t4"]
    @filter.filter(event)
    assert_equal(["t4"], event.tags)

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t1", "t2", "t3"]
    @filter.filter(event)
    assert_equal(["t1"], event.tags)

    event = LogStash::Event.new
    event.type = @typename
    event.tags = ["t1", "t2"]
    @filter.filter(event)
    assert_equal(["t1"], event.tags)
  end
end # Test base filter (via noop)
