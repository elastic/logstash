require 'socket'
require "logstash/filters/elapsed"

describe LogStash::Filters::Elapsed do
  START_TAG = "startTag"
  END_TAG   = "endTag"
  ID_FIELD  = "uniqueIdField"

  def event(data)
    data["message"] ||= "Log message"
    LogStash::Event.new(data)
  end

  def start_event(data)
    data["tags"] ||= []
    data["tags"] << START_TAG
    event(data)
  end

  def end_event(data = {})
    data["tags"] ||= []
    data["tags"] << END_TAG
    event(data)
  end

  before(:each) do
    setup_filter()
  end

  def setup_filter(config = {})
    @config = {"start_tag" => START_TAG, "end_tag" => END_TAG, "unique_id_field" => ID_FIELD}
    @config.merge!(config)
    @filter = LogStash::Filters::Elapsed.new(@config)
    @filter.register
  end

  context "General validation" do
    describe "receiving an event without start or end tag" do
      it "does not record it" do
        @filter.filter(event("message" => "Log message"))
        insist { @filter.start_events.size } == 0
      end
    end

    describe "receiving an event with a different start/end tag from the ones specified in the configuration" do
      it "does not record it" do
        @filter.filter(event("tags" => ["tag1", "tag2"]))
        insist { @filter.start_events.size } == 0
      end
    end
  end

  context "Start event" do
    describe "receiving an event with a valid start tag" do
      describe "but without an unique id field" do
        it "does not record it" do
          @filter.filter(event("tags" => ["tag1", START_TAG]))
          insist { @filter.start_events.size } == 0
        end
      end

      describe "and a valid id field" do
        it "records it" do
          event = start_event(ID_FIELD => "id123")
          @filter.filter(event)

          insist { @filter.start_events.size } == 1
          insist { @filter.start_events["id123"].event } == event
        end
      end
    end

    describe "receiving two 'start events' for the same id field" do
      it "keeps the first one and does not save the second one" do
          args = {"tags" => [START_TAG], ID_FIELD => "id123"}
          first_event = event(args)
          second_event = event(args)

          @filter.filter(first_event)
          @filter.filter(second_event)

          insist { @filter.start_events.size } == 1
          insist { @filter.start_events["id123"].event } == first_event
      end
    end
  end

  context "End event" do
    describe "receiving an event with a valid end tag" do
      describe "and without an id" do
        it "does nothing" do
          insist { @filter.start_events.size } == 0
          @filter.filter(end_event())
          insist { @filter.start_events.size } == 0
        end
      end

      describe "and with an id" do
        describe "but without a previous 'start event'" do
          it "adds a tag 'elapsed.end_witout_start' to the 'end event'" do
            end_event = end_event(ID_FIELD => "id_123")

            @filter.filter(end_event)

            insist { end_event["tags"].include?("elapsed.end_wtihout_start") } == true
          end
        end
      end
    end
  end

  context "Start/end events interaction" do
    describe "receiving a 'start event'" do
      before(:each) do
        @id_value = "id_123"
        @start_event = start_event(ID_FIELD => @id_value)
        @filter.filter(@start_event)
      end

      describe "and receiving an event with a valid end tag" do
        describe "and without an id" do
          it "does nothing" do
            @filter.filter(end_event())
            insist { @filter.start_events.size } == 1
            insist { @filter.start_events[@id_value].event } == @start_event
          end
        end

        describe "and an id different from the one of the 'start event'" do
          it "does nothing" do
            different_id_value = @id_value + "_different"
            @filter.filter(end_event(ID_FIELD => different_id_value))

            insist { @filter.start_events.size } == 1
            insist { @filter.start_events[@id_value].event } == @start_event
          end
        end

        describe "and the same id of the 'start event'" do
          it "deletes the recorded 'start event'" do
            insist { @filter.start_events.size } == 1

            @filter.filter(end_event(ID_FIELD => @id_value))

            insist { @filter.start_events.size } == 0
          end

          shared_examples_for "match event" do
            it "contains the tag 'elapsed'" do
              insist { @match_event["tags"].include?("elapsed") } == true
            end

            it "contains the tag tag 'elapsed.match'" do
              insist { @match_event["tags"].include?("elapsed.match") } == true
            end

            it "contains an 'elapsed.time field' with the elapsed time" do
              insist { @match_event["elapsed.time"] } == 10
            end

            it "contains an 'elapsed.timestamp_start field' with the timestamp of the 'start event'" do
              insist { @match_event["elapsed.timestamp_start"] } == @start_event["@timestamp"]
            end

            it "contains an 'id field'" do
              insist { @match_event[ID_FIELD] } == @id_value
            end
          end

          context "if 'new_event_on_match' is set to 'true'" do
            before(:each) do
              # I need to create a new filter because I need to set
              # the config property 'new_event_on_match" to 'true'.
              setup_filter("new_event_on_match" => true)
              @start_event = start_event(ID_FIELD => @id_value)
              @filter.filter(@start_event)

              end_timestamp = @start_event["@timestamp"] + 10
              end_event = end_event(ID_FIELD => @id_value, "@timestamp" => end_timestamp)
              @filter.filter(end_event) do |new_event|
                @match_event = new_event
              end
            end

            context "creates a new event that" do
              it_behaves_like "match event"

              it "contains the 'host field'" do
                insist { @match_event["host"] } == Socket.gethostname
              end
            end
          end

          context "if 'new_event_on_match' is set to 'false'" do
            before(:each) do
              end_timestamp = @start_event["@timestamp"] + 10
              end_event = end_event(ID_FIELD => @id_value, "@timestamp" => end_timestamp)
              @filter.filter(end_event)

              @match_event = end_event
            end

            context "modifies the 'end event' that" do
              it_behaves_like "match event"
            end
          end

        end
      end
    end
  end

  describe "#flush" do
    def setup(timeout = 1000)
      @config["timeout"] = timeout
      @filter = LogStash::Filters::Elapsed.new(@config)
      @filter.register

      @start_event_1 = start_event(ID_FIELD => "1")
      @start_event_2 = start_event(ID_FIELD => "2")
      @start_event_3 = start_event(ID_FIELD => "3")

      @filter.filter(@start_event_1)
      @filter.filter(@start_event_2)
      @filter.filter(@start_event_3)

      # Force recorded events to different ages
      @filter.start_events["2"].age = 25
      @filter.start_events["3"].age = 26
    end

    it "increments the 'age' of all the recorded 'start events' by 5 seconds" do
      setup()
      old_age = ages()

      @filter.flush()

      ages().each_with_index do |new_age, i|
        insist { new_age } == (old_age[i] + 5)
      end
    end

    def ages()
      @filter.start_events.each_value.map{|element| element.age }
    end

    context "if the 'timeout interval' is set to 30 seconds" do
      before(:each) do
        setup(30)

        @expired_events = @filter.flush()

        insist { @filter.start_events.size } == 1
        insist { @expired_events.size } == 2
      end

      it "deletes the recorded 'start events' with 'age' greater, or equal to, the timeout" do
        insist { @filter.start_events.key?("1") } == true
        insist { @filter.start_events.key?("2") } == false
        insist { @filter.start_events.key?("3") } == false
      end

      it "creates a new event with tag 'elapsed.expired_error' for each expired 'start event'" do
        insist { @expired_events[0]["tags"].include?("elapsed.expired_error") } == true
        insist { @expired_events[1]["tags"].include?("elapsed.expired_error") } == true
      end

      it "creates a new event with tag 'elapsed' for each expired 'start event'" do
        insist { @expired_events[0]["tags"].include?("elapsed") } == true
        insist { @expired_events[1]["tags"].include?("elapsed") } == true
      end

      it "creates a new event containing the 'id field' of the expired 'start event'" do
        insist { @expired_events[0][ID_FIELD] } == "2"
        insist { @expired_events[1][ID_FIELD] } == "3"
      end

      it "creates a new event containing an 'elapsed.time field' with the age of the expired 'start event'" do
        insist { @expired_events[0]["elapsed.time"] } == 30
        insist { @expired_events[1]["elapsed.time"] } == 31
      end

      it "creates a new event containing an 'elapsed.timestamp_start field' with the timestamp of the expired 'start event'" do
        insist { @expired_events[0]["elapsed.timestamp_start"] } == @start_event_2["@timestamp"]
        insist { @expired_events[1]["elapsed.timestamp_start"] } == @start_event_3["@timestamp"]
      end

      it "creates a new event containing a 'host field' for each expired 'start event'" do
        insist { @expired_events[0]["host"] } == Socket.gethostname
        insist { @expired_events[1]["host"] } == Socket.gethostname
      end
    end
  end
end
