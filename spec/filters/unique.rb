require "test_utils"
require "logstash/filters/unique"

describe LogStash::Filters::Unique do
  extend LogStash::RSpec

  describe "unique when field is array" do
    config <<-CONFIG
    filter {
      unique {
        fields => ["noisy_field"]
      }
    }
    CONFIG

    sample("noisy_field" => %w(cat dog cat cat)) do
      insist { subject["noisy_field"] } == %w(cat dog)
    end

    sample("not_an_array" => "Hello, world!") do
      insist { subject["not_an_array"] } == "Hello, world!"
    end

  end
end
