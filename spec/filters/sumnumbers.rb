require "test_utils"
require "logstash/filters/sumnumbers"

describe LogStash::Filters::SumNumbers do
  extend LogStash::RSpec

  describe "sumnumbers test with default values" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        sumnumbers { }
      }
    CONFIG

    sample("message" => "1 bla 3.25 10 100") do
      insist { subject["sumNums"] } == 4
      insist { subject["sumTotal"] } == 114.25
    end
  end

  describe "sumnumbers test with other source field" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        sumnumbers {
          source => 'mysource'
        }
      }
    CONFIG

    sample("mysource" => "1 foo 3.25 10 100") do
      insist { subject["sumNums"] } == 4
      insist { subject["sumTotal"] } == 114.25
    end
  end

end
