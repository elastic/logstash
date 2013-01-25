require "test_utils"
require "logstash/filters/json"

describe LogStash::Filters::Json do
  extend LogStash::RSpec

  describe "parse @message into @fields" do
    config <<-CONFIG
      filter {
        json {
          # Parse @message as JSON, store the results in the 'data' field'
          "@message" => "@fields"
        }
      }
    CONFIG

    sample '{ "hello": "world", "list": [ 1, 2, 3 ], "hash": { "k": "v" } }' do
      insist { subject["hello"] } == "world"
      insist { subject["list" ] } == [1,2,3]
      insist { subject["hash"] } == { "k" => "v" }

      insist { subject["list.0" ] } == 1
      insist { subject["hash.k"] } == "v"
    end
  end

  describe "parse @message into a target field" do
    config <<-CONFIG
      filter {
        json {
          # Parse @message as JSON, store the results in the 'data' field'
          "@message" => "data"
        }
      }
    CONFIG

    sample '{ "hello": "world", "list": [ 1, 2, 3 ], "hash": { "k": "v" } }' do
      insist { subject["data"]["hello"] } == "world"
      insist { subject["data"]["list"] } == [1,2,3]
      insist { subject["data"]["hash"] } == { "k" => "v" }
      
      insist { subject["data.hello"] } == "world"
      insist { subject["data.list" ] } == [1,2,3]
      insist { subject["data.list.0" ] } == 1
      insist { subject["data.hash"] } == { "k" => "v" }
      insist { subject["data.hash.k"] } ==  "v"
    end
  end

  describe "tag invalid json" do
    config <<-CONFIG
      filter {
        json {
          # Parse @message as JSON, store the results in the 'data' field'
          "@message" => "data"
        }
      }
    CONFIG

    sample "invalid json" do
      insist { subject.tags }.include?("_jsonparsefailure")
    end
  end
end
