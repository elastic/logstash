require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash"
require "logstash/loadlibs"
require "logstash/filters"
require "logstash/filters/date"
require "logstash/event"
require "timeout"

describe LogStash::Filters::Date do
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

    @filter = LogStash::Filters::Date.new(cfg)
    @filter.register
  end

  test "ISO8601 date parsing" do
    config "field1" => "ISO8601"

    times = {
      "2001-01-01T00:00:00-0800"         => "2001-01-01T08:00:00.000Z",
      "1974-03-02T04:09:09-0800"         => "1974-03-02T12:09:09.000Z",
      "2010-05-03T08:18:18+00:00"        => "2010-05-03T08:18:18.000Z",
      "2004-07-04T12:27:27-00:00"        => "2004-07-04T12:27:27.000Z",
      "2001-09-05T16:36:36+0000"         => "2001-09-05T16:36:36.000Z",
      "2001-11-06T20:45:45-0000"         => "2001-11-06T20:45:45.000Z",
      "2001-12-07T23:54:54Z"             => "2001-12-07T23:54:54.000Z",

      # TODO: This test assumes PDT
      #"2001-01-01T00:00:00.123"          => "2001-01-01T08:00:00.123Z",

      "2010-05-03T08:18:18.123+00:00"    => "2010-05-03T08:18:18.123Z",
      "2004-07-04T12:27:27.123-04:00"    => "2004-07-04T16:27:27.123Z",
      "2001-09-05T16:36:36.123+0700"     => "2001-09-05T09:36:36.123Z",
      "2001-11-06T20:45:45.123-0000"     => "2001-11-06T20:45:45.123Z",
      "2001-12-07T23:54:54.123Z"         => "2001-12-07T23:54:54.123Z",
    }
    
    event = LogStash::Event.new
    event.type = @typename
    times.each do |input, output|
      event.fields["field1"] = input
      @filter.filter(event)
      assert_equal(output, event.timestamp,
                   "Time '#{input}' should parse to '#{output}' but got '#{event.timestamp}'")
    end # times.each
  end # testing ISO8601

  test "parsing with java SimpleDateFormat syntax" do
    config "field1" => "MMM dd HH:mm:ss Z"

    now = Time.now
    year = now.year
    require 'java'

    times = {
      "Nov 24 01:29:01 -0800" => "#{year}-11-24T09:29:01.000Z",
    }

    event = LogStash::Event.new
    event.type = @typename
    times.each do |input, output|
      event.fields["field1"] = input
      @filter.filter(event)
      assert_equal(output, event.timestamp)
    end
  end # SimpleDateFormat tests

  test "performance" do
    config "field1" => "MMM dd HH:mm:ss Z"
    iterations = 50000

    start = Time.now
    year = start.year

    input = "Nov 24 01:29:01 -0800" 
    output = "#{year}-11-24T09:29:01.000Z"

    event = LogStash::Event.new
    event.type = @typename
    event.fields["field1"] = input
    check_interval = 997
    max_duration = 10
    Timeout.timeout(max_duration) do 
      1.upto(iterations).each do |i|
        @filter.filter(event)
        if i % check_interval == 0
          assert_equal(event.timestamp, output)
        end
      end
    end # Timeout.timeout

    duration = Time.now - start
    puts "filters/date speed test; #{iterations} iterations: #{duration} seconds (#{iterations / duration} per sec)"
    assert(duration < 10, "Should be able to do #{iterations} date parses in less than #{max_duration} seconds, got #{duration} seconds")
  end # performance test

  test "UNIX date parsing" do
    config "field1" => "UNIX"

    times = {
      "0"          => "1970-01-01T00:00:00.000Z",
      "1000000000" => "2001-09-09T01:46:40.000Z",

      # LOGSTASH-279 - sometimes the field is a number.
      0          => "1970-01-01T00:00:00.000Z",
      1000000000 => "2001-09-09T01:46:40.000Z"
    }
    
    event = LogStash::Event.new
    event.type = @typename
    times.each do |input, output|
      event.fields["field1"] = input
      @filter.filter(event)
      assert_equal(output, event.timestamp,
                   "Time '#{input}' should parse to '#{output}' but got '#{event.timestamp}'")
    end # times.each
  end # testing UNIX date parse

  test "UNIX_MS date parsing" do
    config "field1" => "UNIX_MS"

    times = {
      "0"          => "1970-01-01T00:00:00.000Z",
      "456"          => "1970-01-01T00:00:00.456Z",
      "1000000000123" => "2001-09-09T01:46:40.123Z",

      # LOGSTASH-279 - sometimes the field is a number.
      0          => "1970-01-01T00:00:00.000Z",
      456          => "1970-01-01T00:00:00.456Z",
      1000000000123 => "2001-09-09T01:46:40.123Z"
    }
    
    event = LogStash::Event.new
    event.type = @typename
    times.each do |input, output|
      event.fields["field1"] = input
      @filter.filter(event)
      assert_equal(output, event.timestamp,
                   "Time '#{input}' should parse to '#{output}' but got '#{event.timestamp}'")
    end # times.each
  end # testing UNIX date parse
end # describe LogStash::Filters::Date
