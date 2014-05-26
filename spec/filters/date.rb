require "test_utils"
require "logstash/filters/date"

puts "Skipping date performance tests because this ruby is not jruby" if RUBY_ENGINE != "jruby"
RUBY_ENGINE == "jruby" and describe LogStash::Filters::Date do
  extend LogStash::RSpec

  describe "giving an invalid match config, raise a configuration error" do
    config <<-CONFIG
      filter {
        date {
          match => [ "mydate"]
          locale => "en"
        }
      }
    CONFIG

    sample "not_really_important" do
      insist {subject}.raises LogStash::ConfigurationError
    end

  end

  describe "parsing with ISO8601" do
    config <<-CONFIG
      filter {
        date {
          match => [ "mydate", "ISO8601" ]
          locale => "en"
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
      sample("mydate" => input) do
        begin
          insist { subject["mydate"] } == input
          insist { subject["@timestamp"].time } == Time.iso8601(output).utc
        rescue
          #require "pry"; binding.pry
          raise
        end
      end
    end # times.each
  end

  describe "parsing with java SimpleDateFormat syntax" do
    config <<-CONFIG
      filter {
        date {
          match => [ "mydate", "MMM dd HH:mm:ss Z" ]
          locale => "en"
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
      sample("mydate" => input) do
        insist { subject["mydate"] } == input
        insist { subject["@timestamp"].time } == Time.iso8601(output).utc
      end
    end # times.each
  end

  describe "parsing with UNIX" do
    config <<-CONFIG
      filter {
        date {
          match => [ "mydate", "UNIX" ]
          locale => "en"
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
      sample("mydate" => input) do
        insist { subject["mydate"] } == input
        insist { subject["@timestamp"].time } == Time.iso8601(output).utc
      end
    end # times.each
  end

  describe "parsing microsecond-precise times with UNIX (#213)" do
    config <<-CONFIG
      filter {
        date {
          match => [ "mydate", "UNIX" ]
          locale => "en"
        }
      }
    CONFIG

    sample("mydate" => "1350414944.123456") do
      # Joda time only supports milliseconds :\
      insist { subject.timestamp.time } == Time.iso8601("2012-10-16T12:15:44.123-07:00").utc
    end
  end

  describe "parsing with UNIX_MS" do
    config <<-CONFIG
      filter {
        date {
          match => [ "mydate", "UNIX_MS" ]
          locale => "en"
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
      sample("mydate" => input) do
        insist { subject["mydate"] } == input
        insist { subject["@timestamp"].time } == Time.iso8601(output)
      end
    end # times.each
  end

  describe "failed parses should not cause a failure (LOGSTASH-641)" do
    config <<-'CONFIG'
      input {
        generator {
          lines => [
            '{ "mydate": "this will not parse" }',
            '{ }'
          ]
          codec => json
          type => foo
          count => 1
        }
      }
      filter {
        date {
          match => [ "mydate", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
          locale => "en"
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

  describe "TAI64N support" do
    config <<-'CONFIG'
      filter {
        date {
          match => [ "t",  TAI64N ]
          locale => "en"
        }
      }
    CONFIG

    # Try without leading "@"
    sample("t" => "4000000050d506482dbdf024") do
      insist { subject.timestamp.time } == Time.iso8601("2012-12-22T01:00:46.767Z").utc
    end

    # Should still parse successfully if it's a full tai64n time (with leading
    # '@')
    sample("t" => "@4000000050d506482dbdf024") do
      insist { subject.timestamp.time } == Time.iso8601("2012-12-22T01:00:46.767Z").utc
    end
  end

  describe "accept match config option with hash value (LOGSTASH-735)" do
    config <<-CONFIG
      filter {
        date {
          match => [ "mydate", "ISO8601" ]
          locale => "en"
        }
      }
    CONFIG

    time = "2001-09-09T01:46:40.000Z"

    sample("mydate" => time) do
      insist { subject["mydate"] } == time
      insist { subject["@timestamp"].time } == Time.iso8601(time).utc
    end
  end

  describe "support deep nested field access" do
    config <<-CONFIG
      filter {
        date {
          match => [ "[data][deep]", "ISO8601" ]
          locale => "en"
        }
      }
    CONFIG

    sample("data" => { "deep" => "2013-01-01T00:00:00.000Z" }) do
      insist { subject["@timestamp"].time } == Time.iso8601("2013-01-01T00:00:00.000Z").utc
    end
  end

  describe "failing to parse should not throw an exception" do
    config <<-CONFIG
      filter {
        date {
          match => [ "thedate", "yyyy/MM/dd" ]
          locale => "en"
        }
      }
    CONFIG

    sample("thedate" => "2013/Apr/21") do
      insist { subject["@timestamp"] } != "2013-04-21T00:00:00.000Z"
    end
  end

   describe "success to parse should apply on_success config(add_tag,add_field...)" do
    config <<-CONFIG
      filter {
        date {
          match => [ "thedate", "yyyy/MM/dd" ]
          add_tag => "tagged"
        }
      }
    CONFIG

    sample("thedate" => "2013/04/21") do
      insist { subject["@timestamp"] } != "2013-04-21T00:00:00.000Z"
      insist { subject["tags"] } == ["tagged"]
    end
  end

   describe "failing to parse should not apply on_success config(add_tag,add_field...)" do
    config <<-CONFIG
      filter {
        date {
          match => [ "thedate", "yyyy/MM/dd" ]
          add_tag => "tagged"
        }
      }
    CONFIG

    sample("thedate" => "2013/Apr/21") do
      insist { subject["@timestamp"] } != "2013-04-21T00:00:00.000Z"
      insist { subject["tags"] } == nil
    end
  end

  describe "parsing with timezone parameter" do
    config <<-CONFIG
      filter {
        date {
          match => ["mydate", "yyyy MMM dd HH:mm:ss"]
          locale => "en"
          timezone => "America/Los_Angeles"
        }
      }
    CONFIG

    require 'java'
    times = {
      "2013 Nov 24 01:29:01" => "2013-11-24T09:29:01.000Z",
      "2013 Jun 24 01:29:01" => "2013-06-24T08:29:01.000Z",
    }
    times.each do |input, output|
      sample("mydate" => input) do
        insist { subject["mydate"] } == input
        insist { subject["@timestamp"].time } == Time.iso8601(output).utc
      end
    end # times.each
  end

  describe "LOGSTASH-34 - Default year should be this year" do
    config <<-CONFIG
      filter {
        date {
          match => [ "message", "EEE MMM dd HH:mm:ss" ]
          locale => "en"
        }
      }
    CONFIG

    sample "Sun Jun 02 20:38:03" do
      insist { subject["@timestamp"].year } == Time.now.year
    end
  end
end
