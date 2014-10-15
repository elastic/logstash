require "spec_helper"
require "logstash/filters/ruby"
require "logstash/filters/date"

describe LogStash::Filters::Ruby do

  describe "generate pretty json on event.to_hash" do
    # this obviously tests the Ruby filter but also makes sure
    # the fix for issue #1771 is correct and that to_json is
    # compatible with the json gem convention.

    config <<-CONFIG
      filter {
        date {
          match => [ "mydate", "ISO8601" ]
          locale => "en"
          timezone => "UTC"
        }
        ruby {
          init => "require 'json'"
          code => "event['pretty'] = JSON.pretty_generate(event.to_hash)"
        }
      }
    CONFIG

    sample("message" => "hello world", "mydate" => "2014-09-23T00:00:00-0800") do
      # json is rendered in pretty json since the JSON.pretty_generate created json from the event hash
      insist { subject["pretty"] } == "{\n  \"message\": \"hello world\",\n  \"mydate\": \"2014-09-23T00:00:00-0800\",\n  \"@version\": \"1\",\n  \"@timestamp\": \"2014-09-23T08:00:00.000Z\"\n}"
    end
  end

  describe "generate pretty json on event.to_hash" do
    # this obviously tests the Ruby filter but asses that using the json gem directly
    # on even will correctly call the to_json method but will use the logstash json
    # generation and thus will not work with pretty_generate.
    config <<-CONFIG
      filter {
        date {
          match => [ "mydate", "ISO8601" ]
          locale => "en"
          timezone => "UTC"
        }
        ruby {
          init => "require 'json'"
          code => "event['pretty'] = JSON.pretty_generate(event)"
        }
      }
    CONFIG

    sample("message" => "hello world", "mydate" => "2014-09-23T00:00:00-0800") do
      # if this eventually breaks because we removed the custom to_json and/or added pretty support to JrJackson then all is good :)
      insist { subject["pretty"] } == "{\"message\":\"hello world\",\"mydate\":\"2014-09-23T00:00:00-0800\",\"@version\":\"1\",\"@timestamp\":\"2014-09-23T08:00:00.000Z\"}"
    end
  end
end
