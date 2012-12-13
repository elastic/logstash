require "test_utils"
require "logstash/filters/environment"

describe LogStash::Filters::Environment do
  extend LogStash::RSpec

  describe "add a field from the environment" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        environment {
          add_field_from_env => [ "newfield", "MY_ENV_VAR" ]
        }
      }
    CONFIG

    ENV["MY_ENV_VAR"] = "hello world"

    sample "example" do
      insist { subject["newfield"] } == "hello world"
    end
  end

  describe "does nothing on non-matching events" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        environment {
          type => "foo"
          add_field_from_env => [ "newfield", "MY_ENV_VAR" ]
        }
      }
    CONFIG

    ENV["MY_ENV_VAR"] = "hello world"

    sample({ "@type" => "bar", "@message" => "fizz", "@fields" => { } }) do
      insist { subject["newfield"] }.nil?
    end
  end
end
