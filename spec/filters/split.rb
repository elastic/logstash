# encoding: utf-8

require "test_utils"
require "logstash/filters/split"

describe LogStash::Filters::Split do
  extend LogStash::RSpec

  describe "all defaults" do
    config <<-CONFIG
      filter {
        split { }
      }
    CONFIG

    sample "big\nbird\nsesame street" do
      insist { subject.length } == 3
      insist { subject[0]["message"] } == "big"
      insist { subject[1]["message"] } == "bird"
      insist { subject[2]["message"] } == "sesame street"
    end
  end

  describe "custome terminator" do
    config <<-CONFIG
      filter {
        split {
          terminator => "\t"
        }
      }
    CONFIG

    sample "big\tbird\tsesame street" do
      insist { subject.length } == 3
      insist { subject[0]["message"] } == "big"
      insist { subject[1]["message"] } == "bird"
      insist { subject[2]["message"] } == "sesame street"
    end
  end

  describe "custom field" do
    config <<-CONFIG
      filter {
        split {
          field => "custom"
        }
      }
    CONFIG

    sample("custom" => "big\nbird\nsesame street", "do_not_touch" => "1\n2\n3") do
      insist { subject.length } == 3
      subject.each do |s|
         insist { s["do_not_touch"] } == "1\n2\n3"
      end
      insist { subject[0]["custom"] } == "big"
      insist { subject[1]["custom"] } == "bird"
      insist { subject[2]["custom"] } == "sesame street"
    end
  end
end
