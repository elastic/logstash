require "test_utils"
require "logstash/filters/json_encode"

describe LogStash::Filters::JSONEncode do
  extend LogStash::RSpec

  describe "encode a field as json" do
    config <<-CONFIG
      filter {
        json_encode {
          source => "hello"
          target => "fancy"
        }
      }
    CONFIG

    hash = { "hello" => { "whoa" => [ 1,2,3 ] } }
    sample(hash) do
      insist { JSON.parse(subject["fancy"]).to_json } == hash["hello"].to_json
    end
  end

  describe "encode a field as json and overwrite the original" do
    config <<-CONFIG
      filter {
        json_encode {
          source => "hello"
        }
      }
    CONFIG

    hash = { "hello" => { "whoa" => [ 1,2,3 ] } }
    sample(hash) do
      insist { JSON.parse(subject["hello"]).to_json } == hash["hello"].to_json
    end
  end
end
