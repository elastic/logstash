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
    end
  end

  describe "regression - check grok+mutate" do
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
end
