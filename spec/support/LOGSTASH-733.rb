# This spec covers the question here:
# https://logstash.jira.com/browse/LOGSTASH-733

require "test_utils"

describe "LOGSTASH-733" do
  extend LogStash::RSpec
  describe  "pipe-delimited fields" do
    config <<-CONFIG
      filter {
        kv { field_split => "|" }
      }
    CONFIG

    sample "field1=test|field2=another test|field3=test3" do
      insist { subject["field1"] } == "test"
      insist { subject["field2"] } == "another test"
      insist { subject["field3"] } == "test3"
    end
  end
end
