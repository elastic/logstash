require "test_utils"

describe "receive graphite input" do
  extend LogStash::RSpec

  # The logstash config goes here.
  # At this time, only filters are supported.
  config <<-CONFIG
    # input {
    #   tcp {
    #     port => 1234
    #     mode => server
    #     type => graphite
    #   }
    # }
    filter {
      grok {
        pattern => "%{DATA:name} %{NUMBER:value:float} %{POSINT:ts}"
        singles => true
        type => "graphite"
      }
      date {
        type => "graphite"
        ts => UNIX
      }
      mutate {
        type => "graphite"
        remove => ts
      }
    }
  CONFIG

  type "graphite"

  sample 'foo.bar.baz 4025.34 1364606522' do
    insist { subject }.include?("name")
    insist { subject }.include?("value")

    insist { subject["name"] } == "foo.bar.baz"
    insist { subject["value"] } == 4025.34
    insist { subject["@timestamp"] } == "2013-03-30T01:22:02.000Z"
    
  end
end
