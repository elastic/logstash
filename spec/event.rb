# encoding: utf-8

require "logstash/event"
require "insist"

describe LogStash::Event do
  subject do
    LogStash::Event.new(
      "@timestamp" => Time.iso8601("2013-01-01T00:00:00.000Z"),
      "type" => "sprintf",
      "message" => "hello world",
      "tags" => [ "tag1" ],
      "source" => "/home/foo",
      "a" => "b",
      "c" => {
        "d" => "f",
        "e" => {"f" => "g"}
      },
      "f" => { "g" => { "h" => "i" } },
      "j" => {
          "k1" => "v",
          "k2" => [ "w", "x" ],
          "k3" => {"4" => "m"},
          5 => 6,
          "5" => 7
      }
    )
  end

  context "[]=" do
    it "should raise an exception if you attempt to set @timestamp to a value type other than a Time object" do
      insist { subject["@timestamp"] = "crash!" }.raises(TypeError)
    end

    it "should assign simple fields" do
      insist { subject["foo"] }.nil?
      insist { subject["foo"] = "bar"} == "bar"
      insist { subject["foo"] } == "bar"
    end

    it "should overwrite simple fields" do
      insist { subject["foo"] }.nil?
      insist { subject["foo"] = "bar"} == "bar"
      insist { subject["foo"] } == "bar"

      insist { subject["foo"] = "baz"} == "baz"
      insist { subject["foo"] } == "baz"
    end

    it "should assign deep fields" do
      insist { subject["[foo][bar]"] }.nil?
      insist { subject["[foo][bar]"] = "baz"} == "baz"
      insist { subject["[foo][bar]"] } == "baz"
    end

    it "should overwrite deep fields" do
      insist { subject["[foo][bar]"] }.nil?
      insist { subject["[foo][bar]"] = "baz"} == "baz"
      insist { subject["[foo][bar]"] } == "baz"

      insist { subject["[foo][bar]"] = "zab"} == "zab"
      insist { subject["[foo][bar]"] } == "zab"
    end
  end

  context "#sprintf" do
    it "should report a unix timestamp for %{+%s}" do
      insist { subject.sprintf("%{+%s}") } == "1356998400"
    end

    it "should report a time with %{+format} syntax", :if => RUBY_ENGINE == "jruby" do
      insist { subject.sprintf("%{+YYYY}") } == "2013"
      insist { subject.sprintf("%{+MM}") } == "01"
      insist { subject.sprintf("%{+HH}") } == "00"
    end

    it "should report fields with %{field} syntax" do
      insist { subject.sprintf("%{type}") } == "sprintf"
      insist { subject.sprintf("%{message}") } == subject["message"]
    end

    it "should print deep fields" do
      insist { subject.sprintf("%{[j][k1]}") } == "v"
      insist { subject.sprintf("%{[j][k2][0]}") } == "w"
    end

    it "should be able to take a non-string for the format" do
      insist { subject.sprintf(2) } == "2"
    end
  end

  context "#[]" do
    it "should fetch data" do
      insist { subject["type"] } == "sprintf"
    end
    it "should fetch fields" do
      insist { subject["a"] } == "b"
      insist { subject['c']['d'] } == "f"
    end
    it "should fetch deep fields" do
      insist { subject["[j][k1]"] } == "v"
      insist { subject["[c][d]"] } == "f"
      insist { subject['[f][g][h]'] } == "i"
      insist { subject['[j][k3][4]'] } == "m"
      insist { subject['[j][5]'] } == 7

    end

    it "should be fast?", :performance => true do
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
    it "should swap data with new content" do
      new_event = LogStash::Event.new(
        "type" => "new",
        "message" => "foo bar",
      )
      subject.overwrite(new_event)

      insist { subject["message"] } == "foo bar"
      insist { subject["type"] } == "new"

      ["tags", "source", "a", "c", "f", "j"].each do |field|
        insist { subject[field] } == nil
      end
    end
  end

  context "#append" do
    it "should append strings to an array" do
      subject.append(LogStash::Event.new("message" => "another thing"))
      insist { subject["message"] } == [ "hello world", "another thing" ]
    end

    it "should concatenate tags" do
      subject.append(LogStash::Event.new("tags" => [ "tag2" ]))
      insist { subject["tags"] } == [ "tag1", "tag2" ]
    end

    context "when event field is nil" do
      it "should add single value as string" do
        subject.append(LogStash::Event.new({"field1" => "append1"}))
        insist { subject[ "field1" ] } == "append1"
      end
      it "should add multi values as array" do
        subject.append(LogStash::Event.new({"field1" => [ "append1","append2" ]}))
        insist { subject[ "field1" ] } == [ "append1","append2" ]
      end
    end

    context "when event field is a string" do
      before { subject[ "field1" ] = "original1" }

      it "should append string to values, if different from current" do
        subject.append(LogStash::Event.new({"field1" => "append1"}))
        insist { subject[ "field1" ] } == [ "original1", "append1" ]
      end
      it "should not change value, if appended value is equal current" do
        subject.append(LogStash::Event.new({"field1" => "original1"}))
        insist { subject[ "field1" ] } == "original1"
      end
      it "should concatenate values in an array" do
        subject.append(LogStash::Event.new({"field1" => [ "append1" ]}))
        insist { subject[ "field1" ] } == [ "original1", "append1" ]
      end
      it "should join array, removing duplicates" do
        subject.append(LogStash::Event.new({"field1" => [ "append1","original1" ]}))
        insist { subject[ "field1" ] } == [ "original1", "append1" ]
      end
    end
    context "when event field is an array" do
      before { subject[ "field1" ] = [ "original1", "original2" ] }

      it "should append string values to array, if not present in array" do
        subject.append(LogStash::Event.new({"field1" => "append1"}))
        insist { subject[ "field1" ] } == [ "original1", "original2", "append1" ]
      end
      it "should not append string values, if the array already contains it" do
        subject.append(LogStash::Event.new({"field1" => "original1"}))
        insist { subject[ "field1" ] } == [ "original1", "original2" ]
      end
      it "should join array, removing duplicates" do
        subject.append(LogStash::Event.new({"field1" => [ "append1","original1" ]}))
        insist { subject[ "field1" ] } == [ "original1", "original2", "append1" ]
      end
    end
  end

  it "timestamp parsing speed", :performance => true do
    warmup = 10000
    count = 1000000

    data = { "@timestamp" => "2013-12-21T07:25:06.605Z" }
    event = LogStash::Event.new(data)
    insist { event["@timestamp"] }.is_a?(Time)

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

  context "acceptable @timestamp formats" do
    subject { LogStash::Event.new }

    formats = [
      "YYYY-MM-dd'T'HH:mm:ss.SSSZ",
      "YYYY-MM-dd'T'HH:mm:ss.SSSSSSZ",
      "YYYY-MM-dd'T'HH:mm:ss.SSS",
      "YYYY-MM-dd'T'HH:mm:ss",
      "YYYY-MM-dd'T'HH:mm:ssZ",
    ]
    formats.each do |format|
      it "includes #{format}" do
        time = subject.sprintf("%{+#{format}}")
        begin
          LogStash::Event.new("@timestamp" => time)
        rescue => e
          raise StandardError, "Time '#{time}' was rejected. #{e.class}: #{e.to_s}"
        end
      end
    end

    context "from LOGSTASH-1738" do
      it "does not error" do
        LogStash::Event.new("@timestamp" => "2013-12-29T23:12:52.371240+02:00")
      end
    end

    context "from LOGSTASH-1732" do
      it "does not error" do
        LogStash::Event.new("@timestamp" => "2013-12-27T11:07:25+00:00")
      end
    end
  end

  context "timestamp initialization" do
    let(:logger) { double("logger") }

    it "should coerce timestamp" do
      t = Time.iso8601("2014-06-12T00:12:17.114Z")
      expect(LogStash::Timestamp).to receive(:coerce).exactly(3).times.and_call_original
      insist{LogStash::Event.new("@timestamp" => t).timestamp.to_i} == t.to_i
      insist{LogStash::Event.new("@timestamp" => LogStash::Timestamp.new(t)).timestamp.to_i} == t.to_i
      insist{LogStash::Event.new("@timestamp" => "2014-06-12T00:12:17.114Z").timestamp.to_i} == t.to_i
    end

    it "should assign current time when no timestamp" do
      ts = LogStash::Timestamp.now
      expect(LogStash::Timestamp).to receive(:now).and_return(ts)
      insist{LogStash::Event.new({}).timestamp.to_i} == ts.to_i
    end

    it "should tag and warn for invalid value" do
      ts = LogStash::Timestamp.now
      expect(LogStash::Timestamp).to receive(:now).twice.and_return(ts)
      expect(Cabin::Channel).to receive(:get).twice.and_return(logger)
      expect(logger).to receive(:warn).twice

      event = LogStash::Event.new("@timestamp" => :foo)
      insist{event.timestamp.to_i} == ts.to_i
      insist{event["tags"]} == [LogStash::Event::TIMESTAMP_FAILURE_TAG]
      insist{event[LogStash::Event::TIMESTAMP_FAILURE_FIELD]} == :foo

      event = LogStash::Event.new("@timestamp" => 666)
      insist{event.timestamp.to_i} == ts.to_i
      insist{event["tags"]} == [LogStash::Event::TIMESTAMP_FAILURE_TAG]
      insist{event[LogStash::Event::TIMESTAMP_FAILURE_FIELD]} == 666
    end

    it "should tag and warn for invalid string format" do
      ts = LogStash::Timestamp.now
      expect(LogStash::Timestamp).to receive(:now).and_return(ts)
      expect(Cabin::Channel).to receive(:get).and_return(logger)
      expect(logger).to receive(:warn)

      event = LogStash::Event.new("@timestamp" => "foo")
      insist{event.timestamp.to_i} == ts.to_i
      insist{event["tags"]} == [LogStash::Event::TIMESTAMP_FAILURE_TAG]
      insist{event[LogStash::Event::TIMESTAMP_FAILURE_FIELD]} == "foo"
    end
  end
end
