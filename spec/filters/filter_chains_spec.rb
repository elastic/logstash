# encoding: utf-8

require "spec_helper"
require "logstash/filters/split"
require "logstash/filters/clone"

describe LogStash::Filters do
  

  describe "chain split with mutate filter" do
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

  describe "split then multiple mutate" do
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

  describe "split then clone" do
    config <<-CONFIG
      filter {
        split { }
        clone { clones => ['clone1', 'clone2'] }
      }
    CONFIG

    sample "big\nbird" do
      insist { subject.length } == 6

      insist { subject[0]["message"] } == "big"
      insist { subject[0]["type"] } == nil

      insist { subject[1]["message"] } == "big"
      insist { subject[1]["type"] } == "clone1"

      insist { subject[2]["message"] } == "big"
      insist { subject[2]["type"] } == "clone2"

      insist { subject[3]["message"] } == "bird"
      insist { subject[3]["type"] } == nil

      insist { subject[4]["message"] } == "bird"
      insist { subject[4]["type"] } == "clone1"

      insist { subject[5]["message"] } == "bird"
      insist { subject[5]["type"] } == "clone2"
    end
  end

  describe "clone with conditionals, see bug #1548" do
    type "original"
    config <<-CONFIG
      filter {
        clone {
          clones => ["clone"]
        }
        if [type] == "clone" {
          mutate { add_field => { "clone" => "true" } }
        } else {
          mutate { add_field => { "original" => "true" } }
        }
      }
    CONFIG

    sample("message" => "hello world") do
      insist { subject }.is_a? Array
      # subject.each{|event| puts(event.inspect + "\n")}
      insist { subject.length } == 2

      insist { subject.first["type"] } == nil
      insist { subject.first["original"] } == "true"
      insist { subject.first["clone"]} == nil
      insist { subject.first["message"] } == "hello world"

      insist { subject.last["type"]} == "clone"
      insist { subject.last["original"] } == nil
      insist { subject.last["clone"]} == "true"
      insist { subject.last["message"] } == "hello world"
    end
  end

end
