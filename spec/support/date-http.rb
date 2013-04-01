require "test_utils"

describe "http dates" do
  extend LogStash::RSpec

  config <<-'CONFIG'
    filter {
      date {
        timestamp => "dd/MMM/yyyy:HH:mm:ss Z"
      }
    }
  CONFIG

  sample({ "@fields" => { "timestamp" => "25/Mar/2013:20:33:56 +0000" } }) do
    insist { subject["@timestamp"] } == "2013-03-25T20:33:56.000Z"
  end
end
