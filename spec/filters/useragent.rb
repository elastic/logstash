# encoding: utf-8

require "test_utils"
require "logstash/filters/useragent"

describe LogStash::Filters::UserAgent do
  extend LogStash::RSpec

  describe "defaults" do
    config <<-CONFIG
      filter {
        useragent {
          source => "message"
          target => "ua"
        }
      }
    CONFIG

    sample "Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.63 Safari/537.31" do
      insist { subject }.include?("ua")
      insist { subject["ua"]["name"] } == "Chrome"
      insist { subject["ua"]["os"] } == "Linux"
      insist { subject["ua"]["major"] } == "26"
      insist { subject["ua"]["minor"] } == "0"
    end
  end

  describe "" do
    config <<-CONFIG
      filter {
        useragent {
          source => "message"
        }
      }
    CONFIG

    sample "Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.63 Safari/537.31" do
      insist { subject["name"] } == "Chrome"
      insist { subject["os"] } == "Linux"
      insist { subject["major"] } == "26"
      insist { subject["minor"] } == "0"
    end
  end
end
