require "test_utils"
require "logstash/filters/date"

describe LogStash::Filters::Date do
  extend LogStash::RSpec

  describe "parsing with ISO8601" do
    config <<-CONFIG
      filter {
        date {
          mydate => "ISO8601"
        }
      }
    CONFIG

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
    times.each do |input, output|
      sample({"@fields" => {"mydate" => input}}) do
        insist { subject["mydate"] } == input
        insist { subject.timestamp } == output
        insist { subject["@timestamp"] } == output
      end
    end # times.each
  end

  describe "parsing with java SimpleDateFormat syntax" do
    config <<-CONFIG
      filter {
        date {
          mydate => "MMM dd HH:mm:ss Z"
        }
      }
    CONFIG

    now = Time.now
    year = now.year
    require 'java'

    times = {
      "Nov 24 01:29:01 -0800" => "#{year}-11-24T09:29:01.000Z",
    }
    times.each do |input, output|
      sample({"@fields" => {"mydate" => input}}) do
        insist { subject["mydate"] } == input
        insist { subject.timestamp } == output
        insist { subject["@timestamp"] } == output
      end
    end # times.each
  end

  describe "parsing with UNIX" do
    config <<-CONFIG
      filter {
        date {
          mydate => "UNIX"
        }
      }
    CONFIG

    times = {
      "0"          => "1970-01-01T00:00:00.000Z",
      "1000000000" => "2001-09-09T01:46:40.000Z",

      # LOGSTASH-279 - sometimes the field is a number.
      0          => "1970-01-01T00:00:00.000Z",
      1000000000 => "2001-09-09T01:46:40.000Z"
    }
    times.each do |input, output|
      sample({"@fields" => {"mydate" => input}}) do
        insist { subject["mydate"] } == input
        insist { subject.timestamp } == output
        insist { subject["@timestamp"] } == output
      end
    end # times.each
  end

  describe "parsing microsecond-precise times with UNIX (#213)" do
    config <<-CONFIG
      filter {
        date {
          mydate => "UNIX"
        }
      }
    CONFIG

    sample({"@fields" => {"mydate" => "1350414944.123456"}}) do
      insist { subject.timestamp } == "2012-10-16T19:15:44.123Z"
    end
  end

  describe "parsing with UNIX_MS" do
    config <<-CONFIG
      filter {
        date {
          mydate => "UNIX_MS"
        }
      }
    CONFIG

    times = {
      "0"          => "1970-01-01T00:00:00.000Z",
      "456"          => "1970-01-01T00:00:00.456Z",
      "1000000000123" => "2001-09-09T01:46:40.123Z",

      # LOGSTASH-279 - sometimes the field is a number.
      0          => "1970-01-01T00:00:00.000Z",
      456          => "1970-01-01T00:00:00.456Z",
      1000000000123 => "2001-09-09T01:46:40.123Z"
    }
    times.each do |input, output|
      sample({"@fields" => {"mydate" => input}}) do
        insist { subject["mydate"] } == input
        insist { subject.timestamp } == output
        insist { subject["@timestamp"] } == output
      end
    end # times.each
  end

  describe "failed parses should not cause a failure (LOGSTASH-641)" do
    config <<-'CONFIG'
      input {
        generator {
          lines => [
            '{ "@fields": { "mydate": "this will not parse" } }',
            '{ "@fields": { } }'
          ]
          format => json_event
          type => foo
          count => 1
        }
      }
      filter {
        date {
          mydate => [ "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
        }
      }
      output { 
        null { }
      }
    CONFIG

    agent do
      # nothing to do, if this crashes it's an error..
    end
  end

  describe "accept match config option with hash value like grep (LOGSTASH-735)" do
    config <<-CONFIG
      filter {
        date {
          match => [ "mydate", "ISO8601" ]
        }
      }
    CONFIG

    time = "2001-09-09T01:46:40.000Z"

    sample({"@fields" => {"mydate" => time}}) do
      insist { subject["mydate"] } == time
      insist { subject.timestamp } == time
      insist { subject["@timestamp"] } == time
    end
  end
end
