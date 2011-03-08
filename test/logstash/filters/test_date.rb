require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"

require "test/unit"
require "logstash"
require "logstash/loadlibs"
require "logstash/filters"
require "logstash/filters/date"
require "logstash/event"
require "timeout"

$tz = Time.now.strftime("%z")
$TZ = $tz[0..2] + ":" + $tz[3..-1]

class TestFilterDate < Test::Unit::TestCase

  def setup
    ENV["TZ"] = "PST8PDT"
  end

  def test_name(name)
    @typename = name.gsub(/[ ]/, "_")
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

  def test_iso8601
    test_name "iso8601"
    config "field1" => "ISO8601"

    times = {
      "2001-01-01T00:00:00#{$TZ}"        => "2001-01-01T08:00:00.000Z",
      "1974-03-02T04:09:09#{$TZ}"        => "1974-03-02T12:09:09.000Z",
      "2010-05-03T08:18:18+00:00"        => "2010-05-03T08:18:18.000Z",
      "2004-07-04T12:27:27-00:00"        => "2004-07-04T12:27:27.000Z",
      "2001-09-05T16:36:36+0000"         => "2001-09-05T16:36:36.000Z",
      "2001-11-06T20:45:45-0000"         => "2001-11-06T20:45:45.000Z",
      "2001-12-07T23:54:54Z"             => "2001-12-07T23:54:54.000Z",
      "2001-01-01T00:00:00.123"          => "2001-01-01T08:00:00.123Z",

      # older daylights savings?
      "1974-03-02T04:09:09.123"          => "1974-03-02T11:09:09.123Z",
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
    end
  end # def test_iso8601

  def test_formats
    test_name "format test"
    #config "field1" => "%b %e %H:%M:%S"
    config "field1" => "MMM dd HH:mm:ss"

    now = Time.now
    now += now.gmt_offset
    year = now.year
    times = {
      "Nov 24 01:29:01" => "#{year}-11-24T09:29:01.000Z",
    }

    event = LogStash::Event.new
    event.type = @typename
    times.each do |input, output|
      event.fields["field1"] = input
      @filter.filter(event)
      assert_equal(output, event.timestamp)
    end
  end # test_formats

  def test_speed
    test_name "speed test"
    config "field1" => "MMM dd HH:mm:ss"
    iterations = 50000

    start = Time.now
    gmt_now = start + start.gmt_offset
    year = gmt_now.year
    input = "Nov 24 01:29:01" 
    output = "#{year}-11-24T09:29:01.000Z"

    event = LogStash::Event.new
    event.type = @typename
    event.fields["field1"] = input
    check_interval = 1500
    max_duration = 10
    Timeout.timeout(max_duration * 2) do 
      1.upto(50000).each do |i|
        @filter.filter(event)
        if i % check_interval == 0
          assert_equal(event.timestamp, output)
        end
      end
    end # Timeout.timeout

    duration = Time.now - start
    puts "filters/date speed test; #{iterations} iterations: #{duration} seconds (#{iterations / duration} per sec)"
    assert(duration < 10, "Should be able to do #{iterations} date parses in less than #{max_duration} seconds, got #{duration} seconds")
  end # test_formats
end
