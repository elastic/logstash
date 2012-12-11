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

  describe "custom separator" do
    config <<-CONFIG
      filter {
        csv {
          separator => ";"
        }
      }
    CONFIG

    sample "big,bird;sesame street" do
      insist { subject["field1"] } == "big,bird"
      insist { subject["field2"] } == "sesame street"
    end
  end

  describe "parse csv with more data than defined field names" do
    config <<-CONFIG
      filter {
        csv {
          fields => ["custom1", "custom2"]
        }
      }
    CONFIG

    sample "val1,val2,val3" do
      insist { subject["custom1"] } == "val1"
      insist { subject["custom2"] } == "val2"
      insist { subject["field3"] } == "val3"
    end
  end

  describe "parse csv from a given field without field names" do
    config <<-CONFIG
      filter {
        csv {
          raw => "data"
        }
      }
    CONFIG

    sample({"@fields" => {"raw" => "val1,val2,val3"}}) do
      insist { subject["data"]["field1"] } == "val1"
      insist { subject["data"]["field2"] } == "val2"
      insist { subject["data"]["field3"] } == "val3"
    end
  end

  describe "parse csv from a given field with field names" do
    config <<-CONFIG
      filter {
        csv {
          raw => "data"
          fields => ["custom1", "custom2", "custom3"]
        }
      }
    CONFIG

    sample({"@fields" => {"raw" => "val1,val2,val3"}}) do
      insist { subject["data"]["custom1"] } == "val1"
      insist { subject["data"]["custom2"] } == "val2"
      insist { subject["data"]["custom3"] } == "val3"
    end
  end

  describe "fail to parse any data in a multi-value field" do
    config <<-CONFIG
      filter {
        csv {
          raw => "data"
        }
      }
    CONFIG

    sample({"@fields" => {"raw" => ["val1,val2,val3", "val1,val2,val3"]}}) do
      insist { subject["data"] } == nil
    end
  end
end
