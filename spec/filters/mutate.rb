# encoding: utf-8

require "test_utils"
require "logstash/filters/mutate"

describe LogStash::Filters::Mutate do
  extend LogStash::RSpec

  context "config validation" do
   describe "invalid convert type should raise a configuration error" do
      config <<-CONFIG
        filter {
          mutate {
            convert => [ "message", "int"] //should be integer
          }
        }
      CONFIG

      sample "not_really_important" do
        insist {subject}.raises LogStash::ConfigurationError
      end
    end
    describe "invalid gsub triad should raise a configuration error" do
      config <<-CONFIG
        filter {
          mutate {
            gsub => [ "message", "toreplace"]
          }
        }
      CONFIG

      sample "not_really_important" do
        insist {subject}.raises LogStash::ConfigurationError
      end
    end
  end

  describe "basics" do
    config <<-CONFIG
      filter {
        mutate {
          lowercase => "lowerme"
          uppercase => "upperme"
          convert => [ "intme", "integer", "floatme", "float" ]
          rename => [ "rename1", "rename2" ]
          replace => [ "replaceme", "hello world" ]
          replace => [ "newfield", "newnew" ]
          update => [ "nosuchfield", "weee" ]
          update => [ "updateme", "updated" ]
          remove => [ "removeme" ]
        }
      }
    CONFIG

    event = {
      "lowerme" => [ "ExAmPlE" ],
      "upperme" => [ "ExAmPlE" ],
      "intme" => [ "1234", "7890.4", "7.9" ],
      "floatme" => [ "1234.455" ],
      "rename1" => [ "hello world" ],
      "updateme" => [ "who cares" ],
      "replaceme" => [ "who cares" ],
      "removeme" => [ "something" ]
    }

    sample event do
      insist { subject["lowerme"] } == ['example']
      insist { subject["upperme"] } == ['EXAMPLE']
      insist { subject["intme"] }   == [1234, 7890, 7]
      insist { subject["floatme"] } == [1234.455]
      reject { subject }.include?("rename1")
      insist { subject["rename2"] } == [ "hello world" ]
      reject { subject }.include?("removeme")

      insist { subject }.include?("newfield")
      insist { subject["newfield"] } == "newnew"
      reject { subject }.include?("nosuchfield")
      insist { subject["updateme"] } == "updated"
    end
  end

  describe "remove multiple fields" do
    config '
      filter {
        mutate {
          remove => [ "remove-me", "remove-me2", "diedie", "[one][two]" ]
        }
      }'

    sample(
      "remove-me"  => "Goodbye!",
      "remove-me2" => 1234,
      "diedie"     => [1, 2, 3, 4],
      "survivor"   => "Hello.",
      "one" => { "two" => "wee" }
    ) do
      insist { subject["survivor"] } == "Hello."
      reject { subject }.include?("remove-me")
      reject { subject }.include?("remove-me2")
      reject { subject }.include?("diedie")
      reject { subject["one"] }.include?("two")
    end
  end

  describe "convert one field to string" do
    config '
      filter {
        mutate {
          convert => [ "unicorns", "string" ]
        }
      }'

    sample("unicorns" => 1234) do
      insist { subject["unicorns"] } == "1234"
    end
  end

  describe "gsub on a String" do
    config '
      filter {
        mutate {
          gsub => [ "unicorns", "but extinct", "and common" ]
        }
      }'

    sample("unicorns" => "Magnificient, but extinct, animals") do
      insist { subject["unicorns"] } == "Magnificient, and common, animals"
    end
  end

  describe "gsub on an Array of Strings" do
    config '
      filter {
        mutate {
          gsub => [ "unicorns", "extinct", "common" ]
        }
      }'

    sample("unicorns" => [
      "Magnificient extinct animals", "Other extinct ideas" ]
    ) do
      insist { subject["unicorns"] } == [
        "Magnificient common animals",
        "Other common ideas"
      ]
    end
  end

  describe "gsub on multiple fields" do
    config '
      filter {
        mutate {
          gsub => [ "colors", "red", "blue",
                    "shapes", "square", "circle" ]
        }
      }'

    sample("colors" => "One red car", "shapes" => "Four red squares") do
      insist { subject["colors"] } == "One blue car"
      insist { subject["shapes"] } == "Four red circles"
    end
  end

  describe "regression - mutate should lowercase a field created by grok" do
    config <<-CONFIG
      filter {
        grok {
          match => { "message" => "%{WORD:foo}" }
        }
        mutate {
          lowercase => "foo"
        }
      }
    CONFIG

    sample "HELLO WORLD" do
      insist { subject["foo"] } == "hello"
    end
  end

  describe "LOGSTASH-757: rename should do nothing with a missing field" do
    config <<-CONFIG
      filter {
        mutate {
          rename => [ "nosuchfield", "hello" ]
        }
      }
    CONFIG

    sample "whatever" do
      reject { subject }.include?("nosuchfield")
      reject { subject }.include?("hello")
    end
  end

  describe "convert should work on nested fields" do
    config <<-CONFIG
      filter {
        mutate {
          convert => [ "[foo][bar]", "integer" ]
        }
      }
    CONFIG

    sample({ "foo" => { "bar" => "1000" } }) do
      insist { subject["[foo][bar]"] } == 1000
      insist { subject["[foo][bar]"] }.is_a?(Fixnum)
    end
  end

  #LOGSTASH-1529
  describe "gsub on a String with dynamic fields (%{}) in pattern" do
    config '
      filter {
        mutate {
          gsub => [ "unicorns", "of type %{unicorn_type}", "green" ]
        }
      }'

    sample("unicorns" => "Unicorns of type blue are common", "unicorn_type" => "blue") do
      insist { subject["unicorns"] } == "Unicorns green are common"
    end
  end

  #LOGSTASH-1529
  describe "gsub on a String with dynamic fields (%{}) in pattern and replace" do
    config '
      filter {
        mutate {
          gsub => [ "unicorns2", "of type %{unicorn_color}", "%{unicorn_color} and green" ]
        }
      }'

    sample("unicorns2" => "Unicorns of type blue are common", "unicorn_color" => "blue") do
      insist { subject["unicorns2"] } == "Unicorns blue and green are common"
    end
  end

  #LOGSTASH-1529
  describe "gsub on a String array with dynamic fields in pattern" do
    config '
      filter {
        mutate {
          gsub => [ "unicorns_array", "of type %{color}", "blue and green" ]
        }
      }'

    sample("unicorns_array" => [
        "Unicorns of type blue are found in Alaska", "Unicorns of type blue are extinct" ],
           "color" => "blue"
    ) do
      insist { subject["unicorns_array"] } == [
          "Unicorns blue and green are found in Alaska",
          "Unicorns blue and green are extinct"
      ]
    end
  end
end

