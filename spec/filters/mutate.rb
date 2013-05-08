require "test_utils"
require "logstash/filters/mutate"

describe LogStash::Filters::Mutate do
  extend LogStash::RSpec

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

    event = { "@fields" => {
      "lowerme" => [ "ExAmPlE" ],
      "upperme" => [ "ExAmPlE" ],
      "intme" => [ "1234", "7890.4", "7.9" ],
      "floatme" => [ "1234.455" ],
      "rename1" => [ "hello world" ],
      "updateme" => [ "who cares" ],
      "replaceme" => [ "who cares" ],
      "removeme" => [ "something" ]
      }
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
          remove => [ "remove-me", "remove-me2", "diedie" ]
        }
      }'

    sample "@fields" => {
      "remove-me"  => "Goodbye!",
      "remove-me2" => 1234,
      "diedie"     => [1, 2, 3, 4],
      "survivor"   => "Hello."
    } do
      insist { subject.fields } == { "survivor" => "Hello." }
    end
  end

  describe "convert one field to string" do
    config '
      filter {
        mutate {
          convert => [ "unicorns", "string" ]
        }
      }'

    sample "@fields" => {
      "unicorns" => 1234
    } do
      insist { subject.fields } == { "unicorns" => "1234" }
    end
  end

  describe "gsub on a String" do
    config '
      filter {
        mutate {
          gsub => [ "unicorns", "but extinct", "and common" ]
        }
      }'

    sample "@fields" => {
      "unicorns" => "Magnificient, but extinct, animals"
    } do
      insist { subject.fields } == {
        "unicorns" => "Magnificient, and common, animals"
      }
    end
  end

  describe "gsub on an Array of Strings" do
    config '
      filter {
        mutate {
          gsub => [ "unicorns", "extinct", "common" ]
        }
      }'

    sample "@fields" => {
      "unicorns" => [
        "Magnificient extinct animals",
        "Other extinct ideas"
      ]
    } do
      insist { subject.fields } == {
        "unicorns" => [
          "Magnificient common animals",
          "Other common ideas"
        ]
      }
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

    sample "@fields" => {
      "colors" => "One red car",
      "shapes" => "Four red squares"
    } do
      insist { subject.fields } == {
        "colors" => "One blue car",
        "shapes" => "Four red circles"
      }
    end
  end

  describe "regression - mutate should lowercase a field created by grok" do
    config <<-CONFIG
      filter {
        grok {
          pattern => "%{WORD:foo}"
        }
        mutate {
          lowercase => "foo"
        }
      }
    CONFIG

    sample "HELLO WORLD" do
      insist { subject["foo"] } == ['hello']
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
      reject { subject.fields }.include?("nosuchfield")
      reject { subject.fields }.include?("hello")
    end
  end
end

