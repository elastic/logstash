require "test_utils"
require "logstash/filters/edn"

describe LogStash::Filters::Edn do
  extend LogStash::RSpec

  describe "parse message into the event" do
    config <<-CONFIG
      filter {
        edn {
          # Parse message as EDN
          source => "message"
        }
      }
    CONFIG

    sample '{ :hello "world", :list [ 1 2 3 ] , :hash { :k "v" } }' do
      insist { subject["hello"] } == "world"
      insist { subject["list" ] } == [1,2,3]
      insist { subject["hash"]  } == { :k => "v" }
    end
  end

  describe "parse message into a target field" do
    config <<-CONFIG
      filter {
        edn {
          # Parse message as EDN, store the results in the 'data' field'
          source => "message"
          target => "data"
        }
      }
    CONFIG

    sample '{ :hello "world", :list [ 1 2 3 ], :hash { :k "v" } }' do
      insist { subject["data"]["hello"] } == "world"
      insist { subject["data"]["list" ] } == [1,2,3]
      insist { subject["data"]["hash"]  } == { :k => "v" }
    end
  end

  describe "tag invalid edn" do
    config <<-CONFIG
      filter {
        edn {
          # Parse message as EDN, store the results in the 'data' field'
          source => "message"
          target => "data"
        }
      }
    CONFIG

    sample "invalid edn" do
      insist { subject["tags"] }.include?("_ednparsefailure")
    end
  end

  describe "fixing @timestamp (#pull 733)" do
    config <<-CONFIG
      filter {
        edn {
          source => "message"
        }
      }
    CONFIG

    sample "{ :timestamp \"2013-10-19T00:14:32.996Z\" }" do
      insist { subject["timestamp"] }.is_a?(Time)
    end
  end

  describe "source == target" do
    config <<-CONFIG
      filter {
        edn {
          source => "example"
          target => "example"
        }
      }
    CONFIG

    sample({ "example" => "{ :hello \"world\" }" }) do
      insist { subject["example"] }.is_a?(Hash)
      insist { subject["example"]["hello"] } == "world"
    end
  end

end
