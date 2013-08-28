require "test_utils"
require "logstash/filters/drop"

describe LogStash::Filters::Drop do
  extend LogStash::RSpec

  describe "drop the event" do
    config <<-CONFIG
      filter {
        drop { }
      }
    CONFIG

    sample "hello" do
      insist { subject }.nil?
    end
  end

end
