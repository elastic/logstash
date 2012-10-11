require "test_utils"
require "logstash/filters/multiline"

describe LogStash::Filters::Multiline do
  extend LogStash::RSpec

  describe "simple multiline" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
    filter {
      multiline {
        pattern => "^\\s"
        what => previous
      }
    }
    CONFIG

    sample [ "hello world", "   second line", "another first line" ] do
      insist { subject.length } == 2
      insist { subject[0].message } == "hello world\n   second line"
      insist { subject[1].message } == "another first line"
    end
  end

  describe "multiline using grok patterns" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
    filter {
      multiline {
        pattern => "^%{NUMBER} %{TIME}"
        negate => true
        what => previous
      }
    }
    CONFIG

    sample [ "120913 12:04:33 first line", "second line", "third line" ] do
      insist { subject.length } == 1
      insist { subject[0].message } ==  "120913 12:04:33 first line\nsecond line\nthird line"
    end
  end

  describe "multiline safety among multiple concurrent streams" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
    filter {
      multiline {
        pattern => "^\s"
        what => previous
      }
    }
    CONFIG

    multiline_event = [
      "hello world",
      "   line 2",
      "   line 3",
      "   line 4",
      "   line 5",
    ]

    # generate 20 independent streams of this same event, possibly repeated multiple times in each stream
    eventstream = 20.times.collect do |stream|
      multiline_event.collect { |line| LogStash::Event.new("@message" => line, "@type" => stream.to_s) }
    end

    sample eventstream do 
      require "pry"
      binding.pry
    end
  end
end
