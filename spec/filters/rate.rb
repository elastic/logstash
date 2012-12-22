require "test_utils"
require "logstash/filters/rate"
require "time"

# can't use before(:all) with sample()
def sample_messages
  base = Time.now
  (1..100).map do |n|
    LogStash::Event.new( 
      "@message" => "this is message number #{n}",
      "@timestamp" => (base + (n.to_f / 2)).iso8601,
      "@type" => "test",
      "@source" => "test"
    )
  end
end

describe LogStash::Filters::Rate do
  extend LogStash::RSpec
  

  describe "COUNT mode" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
    filter {
      rate {
        mode => "COUNT"
        interval => "10 seconds"
        threshold => 10
        add_tag => "overload"
      }
    }
    CONFIG

    sample sample_messages do
      insist { subject.length } == 100
      (0..9).each do |n|
        reject { subject[1].tags }.include? "overload"
      end
      (10..99).each do |n|
        insist { subject[n].tags }.include? "overload"
      end
    end
  end

  describe "EWMA mode" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
    filter {
      rate {
        mode => "EWMA"
        interval => "10 seconds"
        threshold => 10
        add_tag => "overload"
      }
    }
    CONFIG

    sample sample_messages do
      insist { puts subject[14]; subject.length } == 100
      reject { subject[0..13].reduce([]) {|a, m| a + m.tags } }.include? "overload" 
      (14..99).each do |n|
        insist { subject[n].tags }.include? "overload"
      end
    end
  end

  describe "Rate calculation should be per stream" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
    filter {
      rate {
        mode => "COUNT"
        interval => "10 seconds"
        threshold => 10
        add_tag => "overload"
      }
    }
    CONFIG

    base = Time.new
    another_sample = (1..30).map do |n|
      LogStash::Event.new( 
        "@message" => "2nd stream, message number #{n}",
        "@timestamp" => (base + n).iso8601,
        "@source" => "other source"
      )
    end
    mixed_streams = sample_messages + another_sample
    sample mixed_streams do
      insist { subject.length } == 130
      (0..9).each do |n|
        reject { subject.select {|m| m.source == "test" }[n].tags }.include? "overload"
      end
      (10..99).each do |n|
        insist { subject.select {|m| m.source == "test" }[n].tags }.include? "overload"
      end
      (10..29).each do |n|
        insist { subject.select {|m| m.source == "other source" }[n].tags }.include? "overload"
      end
    end
  end
end
