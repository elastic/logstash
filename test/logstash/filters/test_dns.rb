require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash"
require "logstash/loadlibs"
require "logstash/filters"
require "logstash/filters/dns"
require "logstash/event"
require "timeout"

describe LogStash::Filters::DNS do
  before do
    @typename = "foozle"
  end

  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = [cfg[key]]
      end
    end

    @filter = LogStash::Filters::DNS.new(cfg)
    @filter.register
  end

  ## REVERSE tests

  test "dns reverse lookup, replace (on event.source)" do
    config "reverse" => "@source",
           "action" => "replace"

    event = LogStash::Event.new
    event.type = @typename
    event.source = "199.192.228.250"
    @filter.filter(event)

    assert_equal("carrera.databits.net", event.source)
  end # dns reverse lookup, replace (on event.source)

  test "dns reverse lookup, replace" do
    config "reverse" => "foo",
           "action" => "replace"

    event = LogStash::Event.new
    event.type = @typename
    event["foo"] = ["199.192.228.250"]
    @filter.filter(event)

    assert_equal(["carrera.databits.net"], event["foo"])
  end # dns reverse lookup, replace

  test "dns reverse lookup, append" do
    config "reverse" => "foo",
           "action" => "append"

    event = LogStash::Event.new
    event.type = @typename
    event["foo"] = ["199.192.228.250"]
    @filter.filter(event)

    assert_equal(["199.192.228.250", "carrera.databits.net"], event["foo"])
  end # dns reverse lookup, replace

  test "dns reverse lookup, not an IP" do
    config "reverse" => "foo"

    event = LogStash::Event.new
    event.type = @typename
    event["foo"] = ["not.an.ip"]
    @filter.filter(event)

    assert_equal(["not.an.ip"], event["foo"])
  end # dns reverse lookup, not an IP


  ## RESOLVE tests

  test "dns resolve lookup, replace (on event.source)" do
    config "resolve" => "@source",
           "action" => "replace"

    event = LogStash::Event.new
    event.type = @typename
    event.source = "carrera.databits.net"
    @filter.filter(event)

    assert_equal("199.192.228.250", event.source)
  end # dns reverse lookup, replace (on event.source)

  test "dns resolve lookup, replace" do
    config "resolve" => "foo",
           "action" => "replace"

    event = LogStash::Event.new
    event.type = @typename
    event["foo"] = ["carrera.databits.net"]
    @filter.filter(event)

    assert_equal(["199.192.228.250"], event["foo"])
  end # dns resolve lookup, replace

  test "dns resolve lookup, skip multi-value" do
    config "resolve" => "foo",
           "action" => "replace"

    event = LogStash::Event.new
    event.type = @typename
    event["foo"] = ["carrera.databits.net", "foo.databits.net"]
    @filter.filter(event)

    assert_equal(["carrera.databits.net", "foo.databits.net"], event["foo"])
  end # dns resolve lookup, replace

  test "dns resolve lookup, append" do
    config "resolve" => "foo",
           "action" => "append"

    event = LogStash::Event.new
    event.type = @typename
    event["foo"] = ["carrera.databits.net"]
    @filter.filter(event)

    assert_equal(["carrera.databits.net", "199.192.228.250"], event["foo"])
  end # dns resolve lookup, replace

  test "dns resolve lookup, not a valid hostname" do
    config "resolve" => "foo"

    event = LogStash::Event.new
    event.type = @typename
    event["foo"] = ["does.not.exist"]
    @filter.filter(event)

    assert_equal(["does.not.exist"], event["foo"])
  end # dns resolve lookup, not a valid hostname
end # describe LogStash::Filters::DNS
