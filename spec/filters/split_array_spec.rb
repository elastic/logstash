# encoding: utf-8
require "spec_helper"
require "logstash/filters/split_array"
require 'json'

describe LogStash::Filters::SplitArray do

  describe "int array all defaults" do
    config <<-CONFIG
      filter {
        split_array { }
      }
    CONFIG

    sample JSON.parse('{"message": [ 1,2,3 ] }') do
      insist { subject.length } == 3
      insist { subject[0]["message"] } == 1
      insist { subject[1]["message"] } == 2
      insist { subject[2]["message"] } == 3
    end
  end

  describe "object array field source" do
    config <<-CONFIG
      filter {
        split_array { source => "events" }
      }
    CONFIG

    sample JSON.parse('{"events": [ {"id":"1"}, {"id":"2"} ] }') do
      insist { subject.length } == 2
      insist { subject[0]["message"]["id"] } == "1"
      insist { subject[1]["message"]["id"] } == "2"
    end
  end

end
