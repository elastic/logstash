require "test_utils"
require "logstash/filters/railsparallelrequest"

describe LogStash::Filters::Railsparallelrequest do

  context :filter do

    it "should not process same event twice" do
      filter = LogStash::Filters::Railsparallelrequest.new
      event = LogStash::Event.new({message: "hello world"})
      event.tags=[]
      filter.filter event
      insist { event.tags } == ["railsparallelrequest"]
      filter.filter event
      insist { event.tags } == ["railsparallelrequest"]
    end

    it "should merge multiple events into single event based on unique UUID" do
      filter = LogStash::Filters::Railsparallelrequest.new
      filter.filter event({"message" => "[UUID]hello"})
      filter.filter event({"message" => "[UUID]world"})
      events = filter.flush
      insist { events.first["message"]} == ["[UUID]hello","world"]
    end

    it "should cancel merged events until completed and completed event should have consolidated message" do
      filter = LogStash::Filters::Railsparallelrequest.new
      event1 = event({"message" => "[UUID]hello"})
      filter.filter event1
      insist { event1.cancelled? } == true
      event2 = event({"message" => "[UUID]world"})
      filter.filter event2
      insist { event2.cancelled? } == true
      event3 = event({"message" => "[UUID]Completed"})
      filter.filter event3
      insist { event3.cancelled? } == false
      insist { event3["message"]} == ["[UUID]hello","world", "Completed"]
    end

    it "should not store the completed message" do
      filter = LogStash::Filters::Railsparallelrequest.new
      filter.filter event({"message" => "[UUID]hello"})
      filter.filter event({"message" => "[UUID]Completed"})
      insist { filter.flush.size } == 0
    end

    it "should handle interleaved messages and merge based on UUID" do
      filter = LogStash::Filters::Railsparallelrequest.new
      filter.filter event({"message" => "[UUID1]hello"})
      filter.filter event({"message" => "[UUID2]new"})
      filter.filter event({"message" => "[UUID1]world"})
      filter.filter event({"message" => "[UUID2]world2"})

      uuid1_completed = event({"message" => "[UUID1]Completed"})
      filter.filter uuid1_completed
      insist { uuid1_completed["message"] } == ["[UUID1]hello", "world", "Completed"]

      uuid2_completed = event({"message" => "[UUID2]Completed"})
      filter.filter uuid2_completed
      insist { uuid2_completed["message"] } == ["[UUID2]new", "world2", "Completed"]
    end

    it "should merge message without UUID to previous message with UUID" do
      filter = LogStash::Filters::Railsparallelrequest.new
      filter.filter event({"message" => "[UUID1]hello"})
      filter.filter event({"message" => "new"})
      filter.filter event({"message" => "world"})
      uuid1_completed = event({"message" => "[UUID1]Completed"})
      filter.filter uuid1_completed
      insist { uuid1_completed["message"] } == ["[UUID1]hello", "new", "world", "Completed"]
    end

    it "should not complete on error, wait until next UUID and complete" do
      filter = LogStash::Filters::Railsparallelrequest.new
      filter.filter event({"message" => "[UUID1]hello"})
      filter.filter event({"message" => "new"})
      filter.filter event({"message" => "world"})

      uuid1_completed = event({"message" => "[UUID1]Error"})
      filter.filter(uuid1_completed)
      insist {uuid1_completed.cancelled?} == true

      @error_event = nil
      filter.filter(event({"message" => "[UUID2]Start"})) {|e| @error_event = e}

      insist { @error_event["message"] } == ["[UUID1]hello", "new", "world", "Error"]
      insist {@error_event.cancelled?} == false

    end

    it "should merge following messages even after error" do
      filter = LogStash::Filters::Railsparallelrequest.new
      filter.filter event({"message" => "[UUID1]hello"})
      filter.filter event({"message" => "new"})
      filter.filter event({"message" => "world"})
      filter.filter(event({"message" => "[UUID1]Error"}))
      filter.filter(event({"message" => "[UUID1]StackTrace"}))
      @error_event = nil
      filter.filter(event({"message" => "[UUID2]Start"})) {|e| @error_event = e}

      insist { @error_event["message"] } == ["[UUID1]hello", "new", "world", "Error", "StackTrace"]
    end

  end

end
def event data
  event = LogStash::Event.new(data)
  event.tags=[]
  event
end

