require "test_utils"
require "logstash/filters/extractnumbers"

describe LogStash::Filters::ExtractNumbers do
  extend LogStash::RSpec

  describe "Extract numbers test" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        extractnumbers {
        }
      }
    CONFIG

    sample("message" => "bla 1234 foo 5678 geek 10.43") do
      insist { subject["int1"] } == 1234
      insist { subject["int2"] } == 5678
      insist { subject["float1"] } == 10.43
    end
  end

end
