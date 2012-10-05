require "test_utils"
require "logstash/event"

describe "event tests" do
  extend LogStash::RSpec

  subject { 
    LogStash::Event.new("@fields" => { "foo" => "bar" })
  }

  it "should have @source == 'unknown'" do
    insist { subject["@source"] } == "unknown"
  end

  it "should have a timestamp" do
    insist { subject }.include?("@timestamp")
  end

  it "should have event['foo'] == 'bar'" do
    insist { subject["foo"] } == "bar"
  end
end
