require "test_utils"
require "logstash/filters/multiline"

describe LogStash::Filters::Multiline do
  extend LogStash::RSpec

  describe "simple multiline" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
    filter {
      multiline {
        pattern => "^\\s"
        what => previous
      }
    }
    CONFIG

    sample [ "hello world", "   second line", "another first line" ] do
      insist { subject.length } == 2
      insist { subject[0].message } == "hello world\n   second line"
      insist { subject[1].message } == "another first line"
    end
  end
end
