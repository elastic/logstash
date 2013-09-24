require "test_utils"
require "logstash/filters/sort"

describe LogStash::Filters::Sort do
  extend LogStash::RSpec

  describe "sort when sortSize is full" do
    config <<-CONFIG
      filter {
        sort {
          sortSize => 2
        }
      }
    CONFIG

    events = [
      {
        "@timestamp" => Time.iso8601("2013-01-02T00:00:00.000Z"),
        "message" => "later message"
      },
      {
        "@timestamp" => Time.iso8601("2013-01-01T00:00:00.000Z"),
        "message" => "earlier message"
      }
    ]

    sample(events) do
      insist { subject }.is_a? Array
      insist { subject.length } == 2
      subject.each_with_index do |s,i|
        if i == 0 # first one should be the earlier message
          insist { s["message"] } == "earlier message"
        end
        if i == 1 # second one should be the later message
          insist { s["message"]} == "later message"
        end
      end
    end
  end

  describe "sort by desc" do
    config <<-CONFIG
      filter {
        sort {
          sortSize => 3
          sortBy => "desc"
        }
      }
    CONFIG

    events = [
      {
        "@timestamp" => Time.iso8601("2013-01-03T00:00:00.000Z"),
        "message" => "third message"
      },
      {
        "@timestamp" => Time.iso8601("2013-01-01T00:00:00.000Z"),
        "message" => "first message"
      },
      {
        "@timestamp" => Time.iso8601("2013-01-02T00:00:00.000Z"),
        "message" => "second message"
      }
    ]

    sample(events) do
      insist { subject }.is_a? Array
      insist { subject.length } == 3
      subject.each_with_index do |s,i|
        if i == 0 # first one should be the third message
          insist { s["message"] } == "third message"
        end
        if i == 1 # second one should be the second message
          insist { s["message"]} == "second message"
        end
        if i == 2 # third one should be the third message
          insist { s["message"]} == "first message"
        end
      end
    end
  end

  # (Ignored) Currently this case can't pass because of the case depends on the flush function of the filter in the test, 
  # there was a TODO marked in the code (test_utils.rb, # TODO(sissel): pipeline flush needs to be implemented.), 
  # and the case wants to test the scenario which sort was triggered by a scheduler, so in this case, it needs to sleep few seconds 
  # waiting the scheduler triggered, and after the events were flushed, then the result can be checked.

  # describe "sort when sort interval reached" do
  #   config <<-CONFIG
  #     filter {
  #       sort {
  #         sortInterval => "1s"
  #       }
  #     }
  #   CONFIG

  #   events = [
  #     {
  #       "@timestamp" => Time.iso8601("2013-01-02T00:00:00.000Z"),
  #       "message" => "later message"
  #     },
  #     {
  #       "@timestamp" => Time.iso8601("2013-01-01T00:00:00.000Z"),
  #       "message" => "earlier message"
  #     }
  #   ]

  #   sample(events) do
  #     sleep(2)
  #     insist { subject }.is_a? Array
  #     insist { subject.length } == 2
  #     subject.each_with_index do |s,i|
  #       if i == 0 # first one should be the earlier message
  #         insist { s["message"] } == "earlier message"
  #       end
  #       if i == 1 # second one should be the later message
  #         insist { s["message"]} == "later message"
  #       end
  #     end
  #   end
  # end
end
