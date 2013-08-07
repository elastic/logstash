require "test_utils"
require "logstash/filters/clone"

describe LogStash::Filters::Clone do
  extend LogStash::RSpec

  describe "all defaults" do
    type "original"
    config <<-CONFIG
      filter {
        clone {
          type => "original"
          clones => ["clone", "clone", "clone"]
        }
      }
    CONFIG

    sample("message" => "hello world", "type" => "original") do
      insist { subject }.is_a? Array
      insist { subject.length } == 4
      subject.each_with_index do |s,i|
        if i == 0 # first one should be 'original'
          insist { s["type"] } == "original"
        else
          insist { s["type"]} == "clone"
        end
        insist { s["message"] } == "hello world"
      end
    end
  end

  describe "Complex use" do
    config <<-CONFIG
      filter {
        clone {
          type => "nginx-access"
          tags => ['TESTLOG']
          clones => ["nginx-access-clone1", "nginx-access-clone2"]
          add_tag => ['RABBIT','NO_ES']
          remove_tag => ["TESTLOG"]
        }
      }
    CONFIG

    sample("type" => "nginx-access", "tags" => ["TESTLOG"], "message" => "hello world") do
      insist { subject }.is_a? Array
      insist { subject.length } == 3

      insist { subject[0].type } == "nginx-access"
      #Initial event remains unchanged
      insist { subject[0].tags }.include? "TESTLOG"
      reject { subject[0].tags }.include? "RABBIT"
      reject { subject[0].tags }.include? "NO_ES"
      #All clones go through filter_matched
      insist { subject[1].type } == "nginx-access-clone1"
      reject { subject[1].tags }.include? "TESTLOG"
      insist { subject[1].tags }.include? "RABBIT"
      insist { subject[1].tags }.include? "NO_ES"

      insist { subject[2].type } == "nginx-access-clone2"
      reject { subject[2].tags }.include? "TESTLOG"
      insist { subject[2].tags }.include? "RABBIT"
      insist { subject[2].tags }.include? "NO_ES"
    end
  end

  describe "make deep copies of nested fields" do
    type "original"
    config <<-CONFIG
      filter {
        clone {
          type => "original"
          clones => ["clone"]
        }
      }
    CONFIG

    sample("message" => "hello world", "type" => "original", "hash" => { "nested_hash" => {"value" => "expected"}}) do
      insist { subject }.is_a? Array
      insist { subject.length } == 2
      subject.each_with_index do |s,i|
        if i == 0 # first one should be 'original'
          insist { s["type"] } == "original"
          insist { s["hash"]["nested_hash"]["value"] } == "expected"
          # Manually mutate the original nested value 
          #(could not successfully use a filter on nested field)
          s["hash"]["nested_hash"]["value"] = "mutated"
          insist { s["hash"]["nested_hash"]["value"] } == "mutated"
        else
          insist { s["type"]} == "clone"
          # Cloned event must not be affected by original event changes
          insist { s["hash"]["nested_hash"]["value"] } == "expected"
        end
        insist { s["message"] } == "hello world"
      end
    end
  end

  describe "cloned event should not (?(O_o)?) pass by the complete filter chain" do
    type "original"
    config <<-CONFIG
      filter {
        noop {
          add_tag => ["before"]
        }
        clone {
          type => "original"
          clones => ["clone", "clone", "clone"]
        }
        noop {
          add_tag => ["after"]
        }
      }
    CONFIG

    sample("message" => "hello world", "type" => "original") do
      insist { subject }.is_a? Array
      insist { subject.length } == 4
      subject.each_with_index do |s,i|
        if i == 0 # first one should be 'original'
          insist { s["type"] } == "original"
          insist { s["tags"] }.include?("before")
          insist { s["tags"] }.include?("after")
        else
          insist { s["type"]} == "clone"
          insist { s["tags"] }.include?("after")
          reject { s["tags"] }.include?("before")
        end
        insist { s["message"] } == "hello world"
      end
    end
  end
end
