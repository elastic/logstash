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
        split_array { source => "events" target => "other" }
      }
    CONFIG

    sample JSON.parse('{"events": [ {"id":"1"}, {"id":"2"} ] }') do
      insist { subject.length } == 2
      insist { subject[0]["other"]["id"] } == "1"
      insist { subject[1]["other"]["id"] } == "2"
    end
  end

  describe "not an array" do
    config <<-CONFIG
      filter {
      }
    CONFIG

    sample JSON.parse('{"message": "NA" }') do
      insist { subject["message"] } == "NA"
    end
  end
  describe "clone remove" do
    config <<-CONFIG
      filter {
        split_array { remove_field => "remove" }
      }
    CONFIG

    sample JSON.parse('{"message": [ {"id":"1"}, {"id":"2"} ], "save":"save", "remove":"remove" }') do
      insist { subject.length } == 2
      insist { subject[0]["save"] } == "save"
      insist { subject[0]["remove"] }.nil?
      insist { subject[0]["message"]["id"] } == "1"
      insist { subject[1]["save"] } == "save"
      insist { subject[1]["remove"] }.nil?
      insist { subject[0]["message"]["id"] } == "1"
    end
  end

end
