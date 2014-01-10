require "test_utils"
require "logstash/filters/limit_duplicate"

describe LogStash::Filters::LimitDuplicate do
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


  describe "drop duplicated event by a specific field" do
    config <<-CONFIG
      filter {
        limit_duplicate {
          duplicated_by => ["someField"]
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

  describe "limit only a specific event" do
    config <<-CONFIG
      filter {
        grep {
          add_tag => [ "duplicate" ]
          match => [ "message", "A" ]
          drop => false
        }
        if "duplicate" in [tags] {
          limit_duplicate {
          }
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
      }
    ]

    sample(events) do
      insist { subject }.is_a? Array
      insist { subject.length } == 2
      subject.each_with_index do |s,i|
        if i == 0 # first one should be the messageA
          insist { s["message"] } == "messageA"
        end
        if i == 1 # second one should be the messageA
          insist { s["message"] } == "messageB"
        end
      end
    end
  end

  describe "drop duplicated event by two specific fields" do
    config <<-CONFIG
      filter {
        limit_duplicate {
          duplicated_by => ["someField1", "someField2"]
        }
      }
    CONFIG

    events = [
      {
        "someField1" => "f1A",
        "someField2" => "f2A",
        "message" => "messageA"
      },
      {
        "someField1" => "f1A",
        "someField2" => "f2A",
        "message" => "messageB"
      },
      {
        "someField1" => "f1B",
        "someField2" => "f2A",
        "message" => "messageA"
      },{
        "someField1" => "f1A",
        "someField2" => "f2B",
        "message" => "messageA"
      },
      {
        "someField1" => "f1A",
        "someField2" => "f2B",
        "message" => "messageB"
      },
      {
        "someField1" => "f1A",
        "someField2" => "f2A",
        "message" => "messageC"
      }
    ]

    sample(events) do
      insist { subject }.is_a? Array
      insist { subject.length } == 3
      subject.each_with_index do |s,i|
        if i == 0 # first one should be the messageA, the second and the sixth events will be removed.
          insist { s["message"] } == "messageA"
        end
        if i == 1 # second one should be the messageA, the third event will not be removed.
          insist { s["message"] } == "messageA"
        end
        if i == 2 # third one should be the messageA, the final event will be removed.
          insist { s["message"] } == "messageA"
        end
      end
    end
  end

end
