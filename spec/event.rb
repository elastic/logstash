require "logstash/event"

describe LogStash::Event do
  before :each do
    @event = LogStash::Event.new
    @event.type = "sprintf"
    @event.message = "hello world"
    @event.tags = ["tag1"]
    @event.source = "/home/foo"
  end

  subject { @event }

  describe "#append" do
    it "should append message with \\n" do
      @event.append(LogStash::Event.new("@message" => "hello world"))
      @event.message.should eql "hello world\nhello world"
    end
    it "should concatenate tags" do
      @event.append(LogStash::Event.new("@tags" => ["tag2"]))
      @event.tags.should eql ["tag1", "tag2"]
    end

    context "when event field is nil" do
      it "should add single value as string" do
        @event.append(LogStash::Event.new("@fields" => {"field1" => "append1"}))
        @event["field1"].should eql "append1"
      end
      it "should add multi values as array" do
        @event.append(LogStash::Event.new("@fields" => {"field1" => ["append1","append2"]}))
        @event["field1"].should eql ["append1","append2"]
      end
    end

    context "when event field is a string" do
      before {  @event["field1"] = "original1" }

      it "should append string to values, if different from current" do
        @event.append(LogStash::Event.new("@fields" => {"field1" => "append1"}))
        @event["field1"].should eql ["original1", "append1"]
      end
      it "should not change value, if appended value is equal current" do
        @event.append(LogStash::Event.new("@fields" => {"field1" => "original1"}))
        @event["field1"].should eql "original1"
      end
      it "should concatenate values in an array" do
        @event.append(LogStash::Event.new("@fields" => {"field1" => ["append1"]}))
        @event["field1"].should eql ["original1", "append1"]
      end
      it "should join array, removing duplicates" do
        @event.append(LogStash::Event.new("@fields" => {"field1" => ["append1","original1"]}))
        @event["field1"].should eql ["original1", "append1"]
      end
    end
    context "when event field is an array" do
      before {  @event["field1"] = ["original1", "original2"] }

      it "should append string values to array, if not present in array" do
        @event.append(LogStash::Event.new("@fields" => {"field1" => "append1"}))
        @event["field1"].should eql ["original1", "original2", "append1"]
      end
      it "should not append string values, if the array already contains it" do
        @event.append(LogStash::Event.new("@fields" => {"field1" => "original1"}))
        @event["field1"].should eql ["original1", "original2"]
      end
      it "should join array, removing duplicates" do
        @event.append(LogStash::Event.new("@fields" => {"field1" => ["append1","original1"]}))
        @event["field1"].should eql ["original1", "original2", "append1"]
      end
    end
  end
end
