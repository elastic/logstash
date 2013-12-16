require "test_utils"
require "logstash/filters/collate"

describe LogStash::Filters::Collate do
  extend LogStash::RSpec

  describe "drop duplicated event by default settings" do
    config <<-CONFIG
      filter {
        limit_duplicate {
        }
      }
    CONFIG

    events = [
      {
        "message" => "messageA"
      },
      {
        "message" => "messageB"
      },
      {
        "message" => "messageA"
      },
      {
        "message" => "messageB"
      }
    ]

    sample(events) do
      insist { subject }.is_a? Array
      insist { subject.length } == 2 # the third event with messageA should be droped.
      subject.each_with_index do |s,i|
        if i == 0 # first one should be the messageA
          insist { s["message"] } == "messageA"
        end
        if i == 1 # second one should be the messageB
          insist { s["message"]} == "messageB"
        end
      end
    end
  end


  describe "drop duplicated event by specific field" do
    config <<-CONFIG
      filter {
        limit_duplicate {
          duplicated_by => "someField"
        }
      }
    CONFIG

    events = [
      {
        "someField" => "valueA",
        "message" => "messageA"
      },
      {
        "someField" => "valueA",
        "message" => "messageB"
      },
      {
        "someField" => "valueB",
        "message" => "messageA"
      },{
        "someField" => "valueA",
        "message" => "messageC"
      },
      {
        "someField" => "valueB",
        "message" => "messageD"
      },
      {
        "someField" => "valueC",
        "message" => "messageC"
      }
    ]

    sample(events) do
      insist { subject }.is_a? Array
      insist { subject.length } == 3
      subject.each_with_index do |s,i|
        if i == 0 # first one should be the messageA
          insist { s["message"] } == "messageA"
        end
        if i == 1 # second one should be the messageA
          insist { s["message"] } == "messageA"
        end
        if i == 2 # third one should be the messageC
          insist { s["message"] } == "messageC"
        end
      end
    end
  end

end
