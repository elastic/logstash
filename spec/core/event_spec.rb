# encoding: utf-8
require 'spec_helper'

require "logstash/event"

describe LogStash::Event do

  subject { sample_logstash_event }

  context "[]=" do

    it "should raise an exception if you attempt to set @timestamp to a value type other than a Time object" do
      expect { subject["@timestamp"] = "crash!" }.to raise_error(TypeError)
    end

    context "simple fields" do
      it "access values" do
        expect(subject["foo"]).to be_nil
      end

      it "assign values" do
        expect(subject["foo"] = "bar").to eq("bar")
      end

      it "change values" do
        subject["foo"] = "bar"
        expect(subject["foo"]).to eq("bar")
      end

      it "overrite values" do
        subject["foo"] = "bar"
        subject["foo"] = "baz"
        expect(subject["foo"]).to eq("baz")
      end

    end

    context "deep fields" do

      it "access nil values" do
        expect(subject["[foo][bar]"]).to be_nil
      end

      it "assign values" do
        expect(subject["[foo][bar]"] = "baz").to eq("baz")
      end

      it "change values" do
        subject["[foo][bar]"] = "baz"
        expect(subject["[foo][bar]"]).to eq("baz")
      end

      it "overwrite values" do
        subject["[foo][bar]"] = "baz"
        subject["[foo][bar]"] = "zab"
        expect(subject["[foo][bar]"]).to eq("zab")
      end

    end
  end

  context "#sprintf" do

    it "reports a unix timestamp for %{+%s}" do
      expect(subject.sprintf("%{+%s}")).to eq("1356998400")
    end

    it "reports a time with %{+format} syntax", :if => RUBY_ENGINE == "jruby" do
      expect(subject.sprintf("%{+DD/MM/YYYY}")).to eq("01/01/2013")
    end

    it "reports fields with %{field} syntax" do
      expect(subject.sprintf("%{message}")).to eq(subject["message"])
    end

    it "prints deep fields" do
      expect(subject.sprintf("%{[j][k2][0]}")).to eq("w")
    end

    it "is able to take a non-string for the format" do
      expect(subject.sprintf(2)).to eq("2")
    end

    it "allows to use the metadata" do
      expect(subject.sprintf("super-%{[@metadata][fancy]}")).to eq("super-pants")
    end

    it "allows to use nested hash from the metadata field" do
      expect(subject.sprintf("%{[@metadata][have-to-go][deeper]}")).to eq("inception")
    end
  end

  context "#[]" do

    it "fetch data" do
      expect(subject["type"]).to eq("sprintf")
    end

    it "fetch single fields" do
      expect(subject["a"]).to  eq("b")
    end

    it "fecth inner fields" do
      expect(subject['c']['d']).to eq("f")
    end

    context "deep fields" do

      it "fetch values by name" do
        expect(subject["[j][k1]"]).to eq("v")
      end

      it "fetch values by index" do
        expect(subject['[j][5]']).to eq(7)
      end

      context "multilevel" do
        it "fetch values by name" do
          expect(subject['[f][g][h]']).to eq("i")
        end

        it "fetch values by index" do
          expect(subject['[j][k3][4]']).to eq("m")
        end
      end
    end

    # have to be move somewhere else more relevant.
    xit "is fast enough", :performance => true do
      count = 1000000
      2.times do
        start = Time.now
        count.times { subject["[j][k1]"] }
        duration = Time.now - start
        puts "event #[] rate: #{"%02.0f/sec" % (count / duration)}, elapsed: #{duration}s"
      end
    end
  end

  context "#overwrite" do
    let(:new_event) { LogStash::Event.new("type" => "new", "message" => "foo bar")}

    before(:each) do
      subject.overwrite(new_event)
    end

    it "swap the data with new content" do
      expect(subject["message"]).to eq("foo bar")
    end

    it "remove old values from the event" do
      ["tags", "source", "a", "c", "f", "j"].each do |field|
        expect(subject[field]).to be_nil
      end
    end

  end

  context "#append" do

    it "append strings to an array" do
      subject.append(LogStash::Event.new("message" => "another thing"))
      expect(subject["message"]).to include("hello world", "another thing")
    end

    it "concatenate tags" do
      subject.append(LogStash::Event.new("tags" => [ "tag2" ]))
      expect(subject["tags"]).to include("tag1", "tag2")
    end

    context "when event field is nil" do

      it "add single value as string" do
        subject.append(LogStash::Event.new({"field1" => "append1"}))
        expect(subject[ "field1" ]).to eq("append1")
      end

      it "add multi values as array" do
        subject.append(LogStash::Event.new({"field1" => [ "append1","append2" ]}))
        expect(subject[ "field1" ]).to include("append1","append2")
      end

    end

    context "when event field is a string" do

      before(:each) do
        subject[ "field1" ] = "original1"
      end

      it "append string to values, if different from current" do
        subject.append(LogStash::Event.new({"field1" => "append1"}))
        expect(subject[ "field1" ]).to include("original1", "append1")
      end

      it "not change value, if appended value is equal current" do
        subject.append(LogStash::Event.new({"field1" => "original1"}))
        expect(subject[ "field1" ]).to eq("original1")
      end

      it "concatenate values in an array" do
        subject.append(LogStash::Event.new({"field1" => [ "append1" ]}))
        expect(subject[ "field1" ]).to include("original1", "append1")
      end

      it "join array, removing duplicates" do
        subject.append(LogStash::Event.new({"field1" => [ "append1","original1" ]}))
        expect(subject[ "field1" ]).to include("original1", "append1")
      end
    end

    context "when event field is an array" do

      before(:each) do
        subject[ "field1" ] = [ "original1", "original2" ]
      end

      it "append string values to array, if not present in array" do
        subject.append(LogStash::Event.new({"field1" => "append1"}))
        expect(subject[ "field1" ]).to include("original1", "original2", "append1")
      end

      it "not append string values, if the array already contains it" do
        subject.append(LogStash::Event.new({"field1" => "original1"}))
        expect(subject[ "field1" ]).to include("original1", "original2")
      end

      it "join array, removing duplicates" do
        subject.append(LogStash::Event.new({"field1" => [ "append1","original1" ]}))
        expect(subject[ "field1" ]).to include("original1", "original2", "append1")
      end
    end
  end

  # Should be move somewhere else more relevant
  xit "timestamp parsing speed", :performance => true do
    warmup = 10000
    count = 1000000

    data = { "@timestamp" => "2013-12-21T07:25:06.605Z" }
    event = LogStash::Event.new(data)
    insist { event["@timestamp"] }.is_a?(LogStash::Timestamp)

    duration = 0
    [warmup, count].each do |i|
      start = Time.now
      i.times do
        data = { "@timestamp" => "2013-12-21T07:25:06.605Z" }
        LogStash::Event.new(data.clone)
      end
      duration = Time.now - start
    end
    puts "event @timestamp parse rate: #{"%02.0f/sec" % (count / duration)}, elapsed: #{duration}s"
  end

  context "@timestamp formats" do

    subject { LogStash::Event.new }

    formats = [ "YYYY-MM-dd'T'HH:mm:ss.SSSZ", "YYYY-MM-dd'T'HH:mm:ss.SSSSSSZ",
                "YYYY-MM-dd'T'HH:mm:ss.SSS", "YYYY-MM-dd'T'HH:mm:ss", "YYYY-MM-dd'T'HH:mm:ssZ"]

    formats.each do |format|
      it "includes #{format} as a valid format" do
        time = subject.sprintf("%{+#{format}}")
        expect{LogStash::Event.new("@timestamp" => time)}.not_to raise_error
      end
    end

    context "from LOGSTASH-1738" do
      it "does not error" do
        timestamp = "2013-12-29T23:12:52.371240+02:00"
        expect{LogStash::Event.new("@timestamp" => timestamp)}.not_to raise_error
      end
    end

    context "from LOGSTASH-1732" do
      it "does not error" do
        timestamp = "2013-12-27T11:07:25+00:00"
        expect{LogStash::Event.new("@timestamp" => timestamp)}.not_to raise_error
      end
    end
  end

  context "timestamp initialization" do
    let(:logger) { double("logger") }

    context "time coercion" do
      let(:t) { Time.iso8601("2014-06-12T00:12:17.114Z") }

      before(:each) do
        expect(LogStash::Timestamp).to receive(:coerce).exactly(1).times.and_call_original
      end

      it "match with time" do
        event = LogStash::Event.new("@timestamp" => t)
        expect(event.timestamp.to_i).to eq(t.to_i)
      end

      it "match with a new timestamp" do
        event = LogStash::Event.new("@timestamp" => LogStash::Timestamp.new(t))
        expect(event.timestamp.to_i).to eq(t.to_i)
      end

      it "match with a string" do
        event = LogStash::Event.new("@timestamp" => "2014-06-12T00:12:17.114Z")
        expect(event.timestamp.to_i).to eq(t.to_i)
      end
    end

    it "assign current time when no timestamp" do
      ts = LogStash::Timestamp.now
      event = LogStash::Event.new({})
      expect(event.timestamp.to_i).to eq(ts.to_i)
    end

    context "invalid values" do

      let(:ts) { LogStash::Timestamp.now }

      before(:each) do
        expect(Cabin::Channel).to receive(:get).and_return(logger)
        expect(logger).to receive(:warn)
      end

      context "timestamp as an invalid sym" do
        let(:event) { LogStash::Event.new("@timestamp" => :foo) }

        it "return the current time" do
          expect(event.timestamp.to_i).to eq(ts.to_i)
        end

        it "add a faliure tag" do
          expect(event["tags"]).to include(LogStash::Event::TIMESTAMP_FAILURE_TAG)
        end

        it "add track the invalid value" do
          expect(event[LogStash::Event::TIMESTAMP_FAILURE_FIELD]).to eq(:foo)
        end
      end

      context "timestamp as an invalid number" do
        let(:event) { LogStash::Event.new("@timestamp" => 666) }

        it "return the current time" do
          expect(event.timestamp.to_i).to eq(ts.to_i)
        end

        it "add a faliure tag" do
          expect(event["tags"]).to include(LogStash::Event::TIMESTAMP_FAILURE_TAG)
        end

        it "add track the invalid value" do
          expect(event[LogStash::Event::TIMESTAMP_FAILURE_FIELD]).to eq(666)
        end
      end

      context "timestamp as an invalid string" do
        let(:event) { LogStash::Event.new("@timestamp" => "foo") }

        it "return the current time" do
          expect(event.timestamp.to_i).to eq(ts.to_i)
        end

        it "add a faliure tag" do
          expect(event["tags"]).to include(LogStash::Event::TIMESTAMP_FAILURE_TAG)
        end

        it "add track the invalid value" do
          expect(event[LogStash::Event::TIMESTAMP_FAILURE_FIELD]).to eq("foo")
        end
      end

    end
  end

  context "to_json" do
    let (:timestamp) { Time.iso8601("2014-09-23T19:26:15.832Z") }
    let (:new_event) { LogStash::Event.new("@timestamp" => timestamp, "message" => "foo bar")}

    it "support to_json" do
      json = new_event.to_json
      expect(json).to eq("{\"@timestamp\":\"2014-09-23T19:26:15.832Z\",\"message\":\"foo bar\",\"@version\":\"1\"}")
    end

    it "support to ignore arguments" do
      json = new_event.to_json(:foo => 1, :bar => "baz")
      expect(json).to eq("{\"@timestamp\":\"2014-09-23T19:26:15.832Z\",\"message\":\"foo bar\",\"@version\":\"1\"}")
    end
  end

  context "metadata" do

    context "with existing metadata" do

      subject { LogStash::Event.new("hello" => "world", "@metadata" => { "fancy" => "pants" }).to_hash }

      it "not include in to_hash" do
        expect(subject).not_to include("@metadata")
      end

      it "have expected keys" do
        expect(subject).to include("hello", "@timestamp", "@version")
      end

      it "allow normal field access" do
        expect(subject).to include("hello" => "world")
      end
    end

    context "with set metadata" do
      let(:fieldref) { "[@metadata][foo][bar]" }
      let(:value) { "bar" }
      subject { LogStash::Event.new("normal" => "normal") }

      before(:each) do
        subject[fieldref] = value
      end

      it "allow normal field access" do
        expect(subject.to_hash).to include("normal" => "normal")
      end

      it "allow getting" do
        expect(subject[fieldref]).to eq(value)
      end

      it "is hidden from .to_json" do
        require "json"
        obj = JSON.parse(subject.to_json)
        expect(obj).not_to include("@metadata")
      end

      it "is hidden from .to_hash" do
        expect(subject.to_hash).not_to include("@metadata")
      end

      it "is accessible through #to_hash_with_metadata" do
        obj = subject.to_hash_with_metadata
        expect(obj["@metadata"]["foo"]["bar"]).to eq(value)
      end
    end

    context "with no metadata" do

      subject { LogStash::Event.new("foo" => "bar") }

      it "is hidden from to_hash" do
        expect(subject.to_hash).not_to include("@metadata")
      end

      it "allow normal field access" do
        expect(subject["foo"]).to eq("bar")
      end
    end

  end

end
