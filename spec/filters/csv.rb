require "test_utils"
require "logstash/filters/csv"

describe LogStash::Filters::CSV do
  extend LogStash::RSpec

  describe "basics" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        csv {
          fields => ["first", "last", "zip" ]
        }
      }
    CONFIG

    sample "jordan,sissel,12345" do
      p subject.to_hash
      insist { subject["first"] } == "jordan"
    end
  end
end
