require "test/unit"
require "logstash"
require "logstash/filters"
require "logstash/event"

class TestFilterDate < Test::Unit::TestCase
  def setup
    @filter = LogStash::Filters.from_name("date", {})
  end

  def test_name(name)
    @typename = name
  end

  def config(cfg)
    @filter.add_config(@typename, cfg)
    @filter.register
  end

  def test_iso8601
    test_name "iso8601"
    config "field1" => "ISO8601"

    times = {
      "2001-01-01T00:00:00"               => "2001-01-01T00:00:00.000000Z",
      "1974-03-02T04:09:09"               => "1974-03-02T04:09:09.000000Z",
      "2010-05-03T08:18:18+00:00"         => "2010-05-03T08:18:18.000000Z",
      "2004-07-04T12:27:27-00:00"         => "2004-07-04T12:27:27.000000Z",
      "2001-09-05T16:36:36+0000"          => "2001-09-05T16:36:36.000000Z",
      "2001-11-06T20:45:45-0000"          => "2001-11-06T20:45:45.000000Z",
      "2001-12-07T23:54:54Z"              => "2001-12-07T23:54:54.000000Z",
      "2001-01-01T00:00:00.123456"        => "2001-01-01T00:00:00.123456Z",
      "1974-03-02T04:09:09.123456"        => "1974-03-02T04:09:09.123456Z",
      "2010-05-03T08:18:18.123456+00:00"  => "2010-05-03T08:18:18.123456Z",
      "2004-07-04T12:27:27.123456-04:00"  => "2004-07-04T12:27:27.123456-0400",
      "2001-09-05T16:36:36.123456+0700"   => "2001-09-05T16:36:36.123456+0700",
      "2001-11-06T20:45:45.123456-0000"   => "2001-11-06T20:45:45.123456Z",
      "2001-12-07T23:54:54.123456Z"       => "2001-12-07T23:54:54.123456Z",
    }
    
    event = LogStash::Event.new
    event.type = @typename
    times.each do |input, output|
      event.fields["field1"] = input
      @filter.filter(event)
      assert_equal(output, event.timestamp)
    end
  end # def test_iso8601

  def test_formats
    test_name "format test"
    config "field1" => "%b %e %H:%M:%S"

    now = Time.now
    now += now.gmt_offset
    year = now.year
    times = {
      "Nov 24 01:29:01" => "#{year}-11-24T01:29:01.000000Z",
    }

    event = LogStash::Event.new
    event.type = @typename
    times.each do |input, output|
      event.fields["field1"] = input
      @filter.filter(event)
      assert_equal(output, event.timestamp)
    end
  end # test_formats
end
