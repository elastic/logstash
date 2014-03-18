# encoding: utf-8

require "test_utils"
require "logstash/filters/urldecode"

describe LogStash::Filters::Urldecode do
  extend LogStash::RSpec

  describe "urldecode of correct urlencoded data" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        urldecode {
        }
      }
    CONFIG

    sample("message" => "http%3A%2F%2Flogstash.net%2Fdocs%2F1.3.2%2Ffilters%2Furldecode") do
      insist { subject["message"] } == "http://logstash.net/docs/1.3.2/filters/urldecode"
    end
  end

  describe "urldecode of incorrect urlencoded data" do
    config <<-CONFIG
      filter {
        urldecode {
        }
      }
    CONFIG

    sample("message" => "http://logstash.net/docs/1.3.2/filters/urldecode") do
      insist { subject["message"] } == "http://logstash.net/docs/1.3.2/filters/urldecode"
    end
  end

   describe "urldecode with all_fields set to true" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        urldecode {
          all_fields => true
        }
      }
    CONFIG

    sample("message" => "http%3A%2F%2Flogstash.net%2Fdocs%2F1.3.2%2Ffilters%2Furldecode", "nonencoded" => "http://logstash.net/docs/1.3.2/filters/urldecode") do
      insist { subject["message"] } == "http://logstash.net/docs/1.3.2/filters/urldecode"
      insist { subject["nonencoded"] } == "http://logstash.net/docs/1.3.2/filters/urldecode"
    end

  end

end
