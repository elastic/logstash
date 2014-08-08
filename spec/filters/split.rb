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

  describe "all defaults chain w/ other filter" do
    config <<-CONFIG
      filter {
        split { }
        mutate { replace => [ "message", "test" ] }
      }
    CONFIG

    sample "big\nbird" do
      insist { subject.length } == 2
      insist { subject[0]["message"] } == "test"
      insist { subject[1]["message"] } == "test"
    end
  end

  describe "all defaults chain w/ many other filters" do
    config <<-CONFIG
      filter {
        split { }
        mutate { replace => [ "message", "test" ] }
        mutate { replace => [ "message", "test2" ] }
        mutate { replace => [ "message", "test3" ] }
        mutate { replace => [ "message", "test4" ] }
      }
    CONFIG

    sample "big\nbird" do
      insist { subject.length } == 2
      insist { subject[0]["message"] } == "test4"
      insist { subject[1]["message"] } == "test4"
    end
  end

  describe "all defaults chain w/ mutate and clone filters" do
    config <<-CONFIG
      filter {
        split { }
        mutate { replace => [ "message", "test" ] }
        clone { clones => ['clone1', 'clone2'] }
        mutate { replace => [ "message", "test2" ] }
        mutate { replace => [ "message", "test3" ] }
      }
    CONFIG

    sample "big\nbird" do
      insist { subject.length } == 6
      insist { subject[0]["message"] } == "test3"
      insist { subject[1]["message"] } == "test3"
      insist { subject[2]["message"] } == "test3"
      insist { subject[3]["message"] } == "test3"
      insist { subject[4]["message"] } == "test3"
      insist { subject[5]["message"] } == "test3"
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

  describe "chain split with another filter" do
    config <<-CONFIG
      filter {
        split { }
        mutate { replace => [ "message", "test" ] }
      }
    CONFIG

    sample "hello\nbird" do
      insist { subject.length } == 2
      insist { subject[0]["message"] } == "test"
      insist { subject[1]["message"] } == "test"
    end
  end


  describe "chain split with another filter" do
    config <<-CONFIG
      filter {
        split { }
        mutate { replace => [ "message", "test" ] }
      }
    CONFIG

    sample "hello\nbird" do
    insist { subject.length } == 2
      insist { subject[0]["message"] } == "test"
      insist { subject[1]["message"] } == "test"
    end
  end

  describe "new events bug #793" do
    config <<-CONFIG
      filter {
        split { terminator => "," }
        mutate { rename => { "message" => "fancypants" } }
      }
    CONFIG

    sample "hello,world" do
    insist { subject.length } == 2
      insist { subject[0]["fancypants"] } == "hello"
      insist { subject[1]["fancypants"] } == "world"
    end
  end

end