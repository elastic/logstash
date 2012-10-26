require "test_utils"
require "logstash/filters/csv"

describe LogStash::Filters::CSV do
  extend LogStash::RSpec

  describe "all defaults" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        csv { }
      }
    CONFIG

    sample "big,bird,sesame street" do
      insist { subject["field1"] } == "big"
      insist { subject["field2"] } == "bird"
      insist { subject["field3"] } == "sesame street"
    end
  end

  describe "given fields" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        csv {
          fields => ["first", "last", "address" ]
        }
      }
    CONFIG

    sample "big,bird,sesame street" do
      insist { subject["first"] } == "big"
      insist { subject["last"] } == "bird"
      insist { subject["address"] } == "sesame street"
    end
  end
end
