require "spec_helper"
require "logstash/filters/drop"

describe LogStash::Filters::Drop do

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
