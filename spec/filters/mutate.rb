require "test_utils"
require "logstash/filters/mutate"

describe LogStash::Filters::Mutate do
  extend LogStash::RSpec

  describe "basics" do
    # The logstash config goes here.
    # At this time, only filters are supported.
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
      "lowerme" => [ "ExAmPlE" ], "upperme" => [ "ExAmPlE" ],
      "intme" => [ "1234" ], "floatme" => [ "1234.455" ],
      "rename1" => [ "hello world" ],
      "replaceme" => [ "who cares" ],
      "removeme" => [ "something" ] 
      } 
    } 
    
    sample event do
      insist { subject["lowerme"] } == subject["lowerme"].collect(&:downcase)
      insist { subject["upperme"] } == subject["lowerme"].collect(&:upcase)
      insist { subject["intme"] } == subject["intme"].collect(&:to_i)
      insist { subject["floatme"] } == subject["floatme"].collect(&:to_f)
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
      insist { subject["foo"] } == subject["foo"].collect(&:downcase)
    end
  end
end
