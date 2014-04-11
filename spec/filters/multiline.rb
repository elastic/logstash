# encoding: utf-8

require "test_utils"
require "logstash/filters/multiline"

describe LogStash::Filters::Multiline do

  extend LogStash::RSpec

  describe "simple multiline" do
    config <<-CONFIG
    filter {
      multiline {
        enable_flush => true
        pattern => "^\\s"
        what => previous
      }
    }
    CONFIG

    sample [ "hello world", "   second line", "another first line" ] do
      expect(subject).to be_a(Array)
      insist { subject.size } == 2
      insist { subject[0]["message"] } == "hello world\n   second line"
      insist { subject[1]["message"] } == "another first line"
    end
  end

  describe "multiline using grok patterns" do
    config <<-CONFIG
    filter {
      multiline {
        enable_flush => true
        pattern => "^%{NUMBER} %{TIME}"
        negate => true
        what => previous
      }
    }
    CONFIG

    sample [ "120913 12:04:33 first line", "second line", "third line" ] do
      insist { subject["message"] } ==  "120913 12:04:33 first line\nsecond line\nthird line"
    end
  end

  describe "multiline safety among multiple concurrent streams" do
    config <<-CONFIG
      filter {
        multiline {
          enable_flush => true
          pattern => "^\\s"
          what => previous
        }
      }
    CONFIG

    count = 50
    stream_count = 3

    # first make sure to have starting lines for all streams
    eventstream = stream_count.times.map do |i|
      stream = "stream#{i}"
      lines = [LogStash::Event.new("message" => "hello world #{stream}", "host" => stream, "type" => stream)]
      lines += rand(5).times.map do |n|
        LogStash::Event.new("message" => "   extra line in #{stream}", "host" => stream, "type" => stream)
      end
    end

    # them add starting lines for random stream with sublines also for random stream
    eventstream += (count - stream_count).times.map do |i|
      stream = "stream#{rand(stream_count)}"
      lines = [LogStash::Event.new("message" => "hello world #{stream}", "host" => stream, "type" => stream)]
      lines += rand(5).times.map do |n|
        stream = "stream#{rand(stream_count)}"
        LogStash::Event.new("message" => "   extra line in #{stream}", "host" => stream, "type" => stream)
      end
    end

    events = eventstream.flatten.map{|event| event.to_hash}

    sample events do
      expect(subject).to be_a(Array)
      insist { subject.size } == count

      subject.each_with_index do |event, i|
        insist { event["type"] == event["host"] } == true
        stream = event["type"]
        insist { event["message"].split("\n").first } =~ /hello world /
        insist { event["message"].scan(/stream\d/).all?{|word| word == stream} } == true
      end
    end
  end

  describe "multiline add/remove tags and fields only when matched" do
    config <<-CONFIG
      filter {
        mutate {
          add_tag => "dummy"
        }
        multiline {
          enable_flush => true
          add_tag => [ "nope" ]
          remove_tag => "dummy"
          add_field => [ "dummy2", "value" ]
          pattern => "an unlikely match"
          what => previous
        }
      }
    CONFIG

    sample [ "120913 12:04:33 first line", "120913 12:04:33 second line" ] do
      expect(subject).to be_a(Array)
      insist { subject.size } == 2

      subject.each do |s|
        insist { s["tags"].include?("nope")  } == false
        insist { s["tags"].include?("dummy") } == true
        insist { s.include?("dummy2") } == false
      end
    end
  end

  describe "regression test for GH issue #1258" do
    config <<-CONFIG
      filter {
        multiline {
          pattern => "^\s"
          what => "next"
          add_tag => ["multi"]
        }
      }
    CONFIG

    sample [ "  match", "nomatch" ] do
      expect(subject).to be_a(LogStash::Event)
      insist { subject["message"] } == "  match\nnomatch"
    end
  end

  describe "multiple match/nomatch" do
    config <<-CONFIG
      filter {
        multiline {
          pattern => "^\s"
          what => "next"
          add_tag => ["multi"]
        }
      }
    CONFIG

    sample ["  match1", "nomatch1", "  match2", "nomatch2"] do
      expect(subject).to be_a(Array)
      insist { subject.size } == 2
      insist { subject[0]["message"] } == "  match1\nnomatch1"
      insist { subject[1]["message"] } == "  match2\nnomatch2"
    end
  end
end
