require "logstash/event"
require "insist"

describe LogStash::Event do
  before :each do
    @event = LogStash::Event.new
    @event.timestamp = "2013-01-01T00:00:00.000Z"
    @event.type = "sprintf"
    @event.message = "hello world"
    @event.tags = [ "tag1" ]
    @event.source = "/home/foo"
  end

  subject { @event }

  context "#sprintf" do
    it "should report a time with %{+format} syntax" do
      insist { @event.sprintf("%{+YYYY}") } == "2013"
      insist { @event.sprintf("%{+MM}") } == "01"
      insist { @event.sprintf("%{+HH}") } == "00"
    end

    it "should report fields with %{field} syntax" do
      insist { @event.sprintf("%{@type}") } == "sprintf"
      insist { @event.sprintf("%{@message}") } == subject["@message"]
    end
  end

  context "#append" do
    it "should append message with \\n" do
      subject.append(LogStash::Event.new("@message" => "hello world"))
      insist { subject.message } == "hello world\nhello world"
    end

    it "should concatenate tags" do
      subject.append(LogStash::Event.new("@tags" => [ "tag2" ]))
      insist { subject.tags } == [ "tag1", "tag2" ]
    end

    context "when event field is nil" do
      it "should add single value as string" do
        subject.append(LogStash::Event.new("@fields" => {"field1" => "append1"}))
        insist { subject[ "field1" ] } == "append1"
      end
      it "should add multi values as array" do
        subject.append(LogStash::Event.new("@fields" => {"field1" => [ "append1","append2" ]}))
        insist { subject[ "field1" ] } == [ "append1","append2" ]
      end
    end

    context "when event field is a string" do
      before { subject[ "field1" ] = "original1" }

      it "should append string to values, if different from current" do
        subject.append(LogStash::Event.new("@fields" => {"field1" => "append1"}))
        insist { subject[ "field1" ] } == [ "original1", "append1" ]
      end
      it "should not change value, if appended value is equal current" do
        subject.append(LogStash::Event.new("@fields" => {"field1" => "original1"}))
        insist { subject[ "field1" ] } == [ "original1" ]
      end
      it "should concatenate values in an array" do
        subject.append(LogStash::Event.new("@fields" => {"field1" => [ "append1" ]}))
        insist { subject[ "field1" ] } == [ "original1", "append1" ]
      end
      it "should join array, removing duplicates" do
        subject.append(LogStash::Event.new("@fields" => {"field1" => [ "append1","original1" ]}))
        insist { subject[ "field1" ] } == [ "original1", "append1" ]
      end
    end
    context "when event field is an array" do
      before { subject[ "field1" ] = [ "original1", "original2" ] }

      it "should append string values to array, if not present in array" do
        subject.append(LogStash::Event.new("@fields" => {"field1" => "append1"}))
        insist { subject[ "field1" ] } == [ "original1", "original2", "append1" ]
      end
      it "should not append string values, if the array already contains it" do
        subject.append(LogStash::Event.new("@fields" => {"field1" => "original1"}))
        insist { subject[ "field1" ] } == [ "original1", "original2" ]
      end
      it "should join array, removing duplicates" do
        subject.append(LogStash::Event.new("@fields" => {"field1" => [ "append1","original1" ]}))
        insist { subject[ "field1" ] } == [ "original1", "original2", "append1" ]
      end
    end
  end
end
