require "test_utils"

describe "http dates", :if => RUBY_ENGINE == "jruby" do
  extend LogStash::RSpec

  config <<-'CONFIG'
    filter {
      date {
        match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
        locale => "en"
      }
    }
  CONFIG

  sample("timestamp" => "25/Mar/2013:20:33:56 +0000") do
    insist { subject["@timestamp"].time } == Time.iso8601("2013-03-25T20:33:56.000Z")
  end
end
