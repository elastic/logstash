# encoding: utf-8
require "spec_helper"
require "logstash/util/decorators"
require "json"

describe LogStash::Event do

  shared_examples "all event tests" do
    context "[]=" do
      it "should raise an exception if you attempt to set @timestamp to a value type other than a Time object" do
        expect{subject.set("@timestamp", "crash!")}.to raise_error(TypeError)
      end

      it "should assign simple fields" do
        expect(subject.get("foo")).to be_nil
        expect(subject.set("foo", "bar")).to eq("bar")
        expect(subject.get("foo")).to eq("bar")
      end

      it "should overwrite simple fields" do
        expect(subject.get("foo")).to be_nil
        expect(subject.set("foo", "bar")).to eq("bar")
        expect(subject.get("foo")).to eq("bar")

        expect(subject.set("foo", "baz")).to eq("baz")
        expect(subject.get("foo")).to eq("baz")
      end

      it "should assign deep fields" do
        expect(subject.get("[foo][bar]")).to be_nil
        expect(subject.set("[foo][bar]", "baz")).to eq("baz")
        expect(subject.get("[foo][bar]")).to eq("baz")
      end

      it "should overwrite deep fields" do
        expect(subject.get("[foo][bar]")).to be_nil
        expect(subject.set("[foo][bar]", "baz")).to eq("baz")
        expect(subject.get("[foo][bar]")).to eq("baz")

        expect(subject.set("[foo][bar]", "zab")).to eq("zab")
        expect(subject.get("[foo][bar]")).to eq("zab")
      end

      it "allow to set the @metadata key to a hash" do
        subject.set("@metadata", { "action" => "index" })
        expect(subject.get("[@metadata][action]")).to eq("index")
      end

      it "should add key when setting nil value" do
        subject.set("[baz]", nil)
        expect(subject.to_hash).to include("baz" => nil)
      end

      it "should set nil element within existing array value" do
        subject.set("[foo]", ["bar", "baz"])

        expect(subject.set("[foo][0]", nil)).to eq(nil)
        expect(subject.get("[foo]")).to eq([nil, "baz"])
      end

      it "should set nil in first element within empty array" do
        subject.set("[foo]", [])

        expect(subject.set("[foo][0]", nil)).to eq(nil)
        expect(subject.get("[foo]")).to eq([nil])
      end

      it "should set nil in second element within empty array" do
        subject.set("[foo]", [])

        expect(subject.set("[foo][1]", nil)).to eq(nil)
        expect(subject.get("[foo]")).to eq([nil, nil])
      end
    end

    context "#sprintf" do
      it "should not return a String reference" do
        data = "NOT-A-REFERENCE"
        event = LogStash::Event.new({ "reference" => data })
        LogStash::Util::Decorators.add_fields({"reference_test" => "%{reference}"}, event, "dummy-plugin")
        data.downcase!
        expect(event.get("reference_test")).not_to eq(data)
      end

      it "should not return a Fixnum reference" do
        data = 1
        event = LogStash::Event.new({ "reference" => data })
        LogStash::Util::Decorators.add_fields({"reference_test" => "%{reference}"}, event, "dummy-plugin")
        data += 41
        expect(event.get("reference_test")).to eq("1")
      end

      it "should report a unix timestamp for %{+%s}" do
        expect(subject.sprintf("%{+%s}")).to eq("1356998400")
      end

      it "should work if there is no fieldref in the string" do
        expect(subject.sprintf("bonjour")).to eq("bonjour")
      end

      it "should raise error when formatting %{+%s} when @timestamp field is missing" do
        str = "hello-%{+%s}"
        subj = subject.clone
        subj.remove("[@timestamp]")
        expect{ subj.sprintf(str) }.to raise_error(LogStash::Error)
      end

      it "should report a time with %{+format} syntax", :if => RUBY_ENGINE == "jruby" do
        expect(subject.sprintf("%{+YYYY}")).to eq("2013")
        expect(subject.sprintf("%{+MM}")).to eq("01")
        expect(subject.sprintf("%{+HH}")).to eq("00")
      end

      it "should support mixed string" do
        expect(subject.sprintf("foo %{+YYYY-MM-dd} %{type}")).to eq("foo 2013-01-01 sprintf")
      end

      it "should raise error with %{+format} syntax when @timestamp field is missing", :if => RUBY_ENGINE == "jruby" do
        str = "logstash-%{+YYYY}"
        subj = subject.clone
        subj.remove("[@timestamp]")
        expect{ subj.sprintf(str) }.to raise_error(LogStash::Error)
      end

      it "should report fields with %{field} syntax" do
        expect(subject.sprintf("%{type}")).to eq("sprintf")
        expect(subject.sprintf("%{message}")).to eq(subject.get("message"))
      end

      it "should print deep fields" do
        expect(subject.sprintf("%{[j][k1]}")).to eq("v")
        expect(subject.sprintf("%{[j][k2][0]}")).to eq("w")
      end

      it "should be able to take a non-string for the format" do
        expect(subject.sprintf(2)).to eq("2")
      end

      it "should allow to use the metadata when calling #sprintf" do
        expect(subject.sprintf("super-%{[@metadata][fancy]}")).to eq("super-pants")
      end

      it "should allow to use nested hash from the metadata field" do
        expect(subject.sprintf("%{[@metadata][have-to-go][deeper]}")).to eq("inception")
      end

      it "should return a json string if the key is a hash" do
        expect(subject.sprintf("%{[j][k3]}")).to eq("{\"4\":\"m\"}")
      end

      it "should not strip last character" do
        expect(subject.sprintf("%{type}%{message}|")).to eq("sprintfhello world|")
      end

      it "should render nil array values as leading empty string" do
        expect(subject.set("foo", [nil, "baz"])).to eq([nil, "baz"])

        expect(subject.get("[foo][0]")).to be_nil
        expect(subject.get("[foo][1]")).to eq("baz")

        expect(subject.sprintf("%{[foo]}")).to eq(",baz")
      end

      it "should render nil array values as middle empty string" do
        expect(subject.set("foo", ["bar", nil, "baz"])).to eq(["bar", nil, "baz"])

        expect(subject.get("[foo][0]")).to eq("bar")
        expect(subject.get("[foo][1]")).to be_nil
        expect(subject.get("[foo][2]")).to eq("baz")

        expect(subject.sprintf("%{[foo]}")).to eq("bar,,baz")
      end

     it "should render nil array values as trailing empty string" do
        expect(subject.set("foo", ["bar", nil])).to eq(["bar", nil])

        expect(subject.get("[foo][0]")).to eq("bar")
        expect(subject.get("[foo][1]")).to be_nil

        expect(subject.sprintf("%{[foo]}")).to eq("bar,")
     end

      it "should render deep arrays with nil value" do
        subject.set("[foo]", [[12, nil], 56])
        expect(subject.sprintf("%{[foo]}")).to eq("12,,56")
      end

      context "#encoding" do
        it "should return known patterns as UTF-8" do
          expect(subject.sprintf("%{message}").encoding).to eq(Encoding::UTF_8)
        end

        it "should return unknown patterns as UTF-8" do
          expect(subject.sprintf("%{unkown_pattern}").encoding).to eq(Encoding::UTF_8)
        end
      end
    end

    context "#[]" do
      it "should fetch data" do
        expect(subject.get("type")).to eq("sprintf")
      end
      it "should fetch fields" do
        expect(subject.get("a")).to eq("b")
        expect(subject.get('c')['d']).to eq("f")
      end
      it "should fetch deep fields" do
        expect(subject.get("[j][k1]")).to eq("v")
        expect(subject.get("[c][d]")).to eq("f")
        expect(subject.get('[f][g][h]')).to eq("i")
        expect(subject.get('[j][k3][4]')).to eq("m")
        expect(subject.get('[j][5]')).to eq(7)

      end

      it "should be fast?", :performance => true do
        count = 1000000
        2.times do
          start = Time.now
          count.times { subject.get("[j][k1]") }
          duration = Time.now - start
          puts "event #[] rate: #{"%02.0f/sec" % (count / duration)}, elapsed: #{duration}s"
        end
      end
    end

    context "#include?" do
      it "should include existing fields" do
        expect(subject.include?("c")).to eq(true)
        expect(subject.include?("[c][d]")).to eq(true)
        expect(subject.include?("[j][k4][0][nested]")).to eq(true)
      end

      it "should include field with nil value" do
        expect(subject.include?("nilfield")).to eq(true)
      end

      it "should include @metadata field" do
        expect(subject.include?("@metadata")).to eq(true)
      end

      it "should include field within @metadata" do
        expect(subject.include?("[@metadata][fancy]")).to eq(true)
      end

      it "should not include non-existing fields" do
        expect(subject.include?("doesnotexist")).to eq(false)
        expect(subject.include?("[j][doesnotexist]")).to eq(false)
        expect(subject.include?("[tag][0][hello][yes]")).to eq(false)
      end

      it "should include within arrays" do
        expect(subject.include?("[tags][0]")).to eq(true)
        expect(subject.include?("[tags][1]")).to eq(false)
      end
    end

    context "#overwrite" do
      it "should swap data with new content" do
        new_event = LogStash::Event.new(
          "type" => "new",
          "message" => "foo bar",
        )
        subject.overwrite(new_event)

        expect(subject.get("message")).to eq("foo bar")
        expect(subject.get("type")).to eq("new")

        ["tags", "source", "a", "c", "f", "j"].each do |field|
          expect(subject.get(field)).to be_nil
        end
      end
    end

    context "#append" do
      it "should append strings to an array" do
        subject.append(LogStash::Event.new("message" => "another thing"))
        expect(subject.get("message")).to eq([ "hello world", "another thing" ])
      end

      it "should concatenate tags" do
        subject.append(LogStash::Event.new("tags" => [ "tag2" ]))
        # added to_a for when array is a Java Collection when produced from json input
        # TODO: we have to find a better way to handle this in tests. maybe override
        # rspec eq or == to do an explicit to_a when comparing arrays?
        expect(subject.get("tags").to_a).to eq([ "tag1", "tag2" ])
      end

      context "when event field is nil" do
        it "should add single value as string" do
          subject.append(LogStash::Event.new({"field1" => "append1"}))
          expect(subject.get("field1")).to eq("append1")
        end
        it "should add multi values as array" do
          subject.append(LogStash::Event.new({"field1" => [ "append1","append2" ]}))
          expect(subject.get("field1")).to eq([ "append1","append2" ])
        end
      end

      context "when event field is a string" do
        before { subject.set("field1", "original1") }

        it "should append string to values, if different from current" do
          subject.append(LogStash::Event.new({"field1" => "append1"}))
          expect(subject.get("field1")).to eq([ "original1", "append1" ])
        end
        it "should not change value, if appended value is equal current" do
          subject.append(LogStash::Event.new({"field1" => "original1"}))
          expect(subject.get("field1")).to eq("original1")
        end
        it "should concatenate values in an array" do
          subject.append(LogStash::Event.new({"field1" => [ "append1" ]}))
          expect(subject.get("field1")).to eq([ "original1", "append1" ])
        end
        it "should join array, removing duplicates" do
          subject.append(LogStash::Event.new({"field1" => [ "append1","original1" ]}))
          expect(subject.get("field1")).to eq([ "original1", "append1" ])
        end
      end
      context "when event field is an array" do
        before { subject.set("field1", [ "original1", "original2" ] )}

        it "should append string values to array, if not present in array" do
          subject.append(LogStash::Event.new({"field1" => "append1"}))
          expect(subject.get("field1")).to eq([ "original1", "original2", "append1" ])
        end
        it "should not append string values, if the array already contains it" do
          subject.append(LogStash::Event.new({"field1" => "original1"}))
          expect(subject.get("field1")).to eq([ "original1", "original2" ])
        end
        it "should join array, removing duplicates" do
          subject.append(LogStash::Event.new({"field1" => [ "append1","original1" ]}))
          expect(subject.get("field1")).to eq([ "original1", "original2", "append1" ])
        end
      end

    end

    it "timestamp parsing speed", :performance => true do
      warmup = 10000
      count = 1000000

      data = { "@timestamp" => "2013-12-21T07:25:06.605Z" }
      event = LogStash::Event.new(data)
      expect(event.get("@timestamp")).to be_a(LogStash::Timestamp)

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
      it "should coerce timestamp" do
        t = Time.iso8601("2014-06-12T00:12:17.114Z")
        expect(LogStash::Event.new("@timestamp" => t).timestamp.to_i).to eq(t.to_i)
        expect(LogStash::Event.new("@timestamp" => LogStash::Timestamp.new(t)).timestamp.to_i).to eq(t.to_i)
        expect(LogStash::Event.new("@timestamp" => "2014-06-12T00:12:17.114Z").timestamp.to_i).to eq(t.to_i)
      end

      it "should assign current time when no timestamp" do
        expect(LogStash::Event.new({}).timestamp.to_i).to be_within(1).of (Time.now.to_i)
      end

      it "should tag for invalid value" do
        event = LogStash::Event.new("@timestamp" => "foo")
        expect(event.timestamp.to_i).to be_within(1).of Time.now.to_i
        expect(event.get("tags")).to eq([LogStash::Event::TIMESTAMP_FAILURE_TAG])
        expect(event.get(LogStash::Event::TIMESTAMP_FAILURE_FIELD)).to eq("foo")

        event = LogStash::Event.new("@timestamp" => 666)
        expect(event.timestamp.to_i).to be_within(1).of Time.now.to_i
        expect(event.get("tags")).to eq([LogStash::Event::TIMESTAMP_FAILURE_TAG])
        expect(event.get(LogStash::Event::TIMESTAMP_FAILURE_FIELD)).to eq(666)
      end

      it "should warn for invalid value" do
        LogStash::Event.new("@timestamp" => :foo)
        LogStash::Event.new("@timestamp" => 666)
      end

      it "should tag for invalid string format" do
        event = LogStash::Event.new("@timestamp" => "foo")
        expect(event.timestamp.to_i).to be_within(1).of Time.now.to_i
        expect(event.get("tags")).to eq([LogStash::Event::TIMESTAMP_FAILURE_TAG])
        expect(event.get(LogStash::Event::TIMESTAMP_FAILURE_FIELD)).to eq("foo")
      end

      it "should warn for invalid string format" do
        LogStash::Event.new("@timestamp" => "foo")
      end
    end

    context "to_json" do
      it "should support to_json" do
        new_event = LogStash::Event.new(
          "@timestamp" => Time.iso8601("2014-09-23T19:26:15.832Z"),
          "message" => "foo bar",
        )
        json = new_event.to_json

        expect(JSON.parse(json)).to eq( JSON.parse("{\"@timestamp\":\"2014-09-23T19:26:15.832Z\",\"message\":\"foo bar\",\"@version\":\"1\"}"))
      end

      it "should support to_json and ignore arguments" do
        new_event = LogStash::Event.new(
          "@timestamp" => Time.iso8601("2014-09-23T19:26:15.832Z"),
          "message" => "foo bar",
        )
        json = new_event.to_json(:foo => 1, :bar => "baz")

        expect(JSON.parse(json)).to eq( JSON.parse("{\"@timestamp\":\"2014-09-23T19:26:15.832Z\",\"message\":\"foo bar\",\"@version\":\"1\"}"))
      end
    end

    context "metadata" do
      context "with existing metadata" do
        subject { LogStash::Event.new("hello" => "world", "@metadata" => { "fancy" => "pants" }) }

        it "should not include metadata in to_hash" do
          expect(subject.to_hash.keys).not_to include("@metadata")

          # 'hello', '@timestamp', and '@version'
          expect(subject.to_hash.keys.count).to eq(3)
        end

        it "should still allow normal field access" do
          expect(subject.get("hello")).to eq("world")
        end
      end

      context "with set metadata" do
        let(:fieldref) { "[@metadata][foo][bar]" }
        let(:value) { "bar" }
        subject { LogStash::Event.new("normal" => "normal") }
        before do
          # Verify the test is configured correctly.
          expect(fieldref).to start_with("[@metadata]")

          # Set it.
          subject.set(fieldref, value)
        end

        it "should still allow normal field access" do
          expect(subject.get("normal")).to eq("normal")
        end

        it "should allow getting" do
          expect(subject.get(fieldref)).to eq(value)
        end

        it "should be hidden from .to_json" do
          require "json"
          obj = JSON.parse(subject.to_json)
          expect(obj).not_to include("@metadata")
        end

        it "should be hidden from .to_hash" do
          expect(subject.to_hash).not_to include("@metadata")
        end

        it "should be accessible through #to_hash_with_metadata" do
          obj = subject.to_hash_with_metadata
          expect(obj).to include("@metadata")
          expect(obj["@metadata"]["foo"]["bar"]).to eq(value)
        end
      end

      context "with no metadata" do
        subject { LogStash::Event.new("foo" => "bar") }
        it "should have no metadata" do
          expect(subject.get("@metadata")).to be_empty
        end
        it "should still allow normal field access" do
          expect(subject.get("foo")).to eq("bar")
        end

        it "should not include the @metadata key" do
          expect(subject.to_hash_with_metadata).not_to include("@metadata")
        end
      end
    end

    context "signal events" do
      it "should define the shutdown and flush event constants" do
        # the SHUTDOWN and FLUSH constants are part of the plugin API contract
        # if they are changed, all plugins must be updated
        expect(LogStash::SHUTDOWN).to be_a(LogStash::ShutdownEvent)
        expect(LogStash::FLUSH).to be_a(LogStash::FlushEvent)
      end

      it "should define the shutdown event with SignalEvent as parent class" do
        expect(LogStash::SHUTDOWN).to be_a(LogStash::SignalEvent)
        expect(LogStash::FLUSH).to be_a(LogStash::SignalEvent)
      end

      it "should define the flush? method" do
        expect(LogStash::SHUTDOWN.flush?).to be_falsey
        expect(LogStash::FLUSH.flush?).to be_truthy
      end

      it "should define the shutdown? method" do
        expect(LogStash::SHUTDOWN.shutdown?).to be_truthy
        expect(LogStash::FLUSH.shutdown?).to be_falsey
      end
    end
  end

  let(:event_hash) do
    {
      "@timestamp" => "2013-01-01T00:00:00.000Z",
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
          "k4" => [ {"nested" => "cool"} ],
          5 => 6,
          "5" => 7
      },
      "nilfield" => nil,
      "@metadata" => { "fancy" => "pants", "have-to-go" => { "deeper" => "inception" } }
    }
  end

  describe "using normal hash input" do
    it_behaves_like "all event tests" do
      subject{LogStash::Event.new(event_hash)}
    end
  end

  describe "using hash input from deserialized json" do
    # this is to test the case when JrJackson deserialises Json and produces
    # native Java Collections objects for efficiency
    it_behaves_like "all event tests" do
      subject{LogStash::Event.new(LogStash::Json.load(LogStash::Json.dump(event_hash)))}
    end
  end


  describe "#to_s" do
    let(:timestamp) { LogStash::Timestamp.new }
    let(:event1) { LogStash::Event.new({ "@timestamp" => timestamp, "host" => "foo", "message" => "bar"}) }
    let(:event2) { LogStash::Event.new({ "host" => "bar", "message" => "foo"}) }

    it "should cache only one template" do
      LogStash::StringInterpolation.clear_cache
      expect {
        event1.to_s
        event2.to_s
      }.to change { LogStash::StringInterpolation.cache_size }.by(1)
    end

    it "return the string containing the timestamp, the host and the message" do
      expect(event1.to_s).to eq("#{timestamp.to_iso8601} #{event1.get("host")} #{event1.get("message")}")
    end
  end

  describe "Event accessors" do
    let(:event) { LogStash::Event.new({ "message" => "foo" }) }

    it "should invalidate target caching" do
      expect(event.get("[a][0]")).to be_nil

      expect(event.set("[a][0]", 42)).to eq(42)
      expect(event.get("[a][0]")).to eq(42)
      expect(event.get("[a]")).to eq({"0" => 42})

      expect(event.set("[a]", [42, 24])).to eq([42, 24])
      expect(event.get("[a]")).to eq([42, 24])

      expect(event.get("[a][0]")).to eq(42)

      expect(event.set("[a]", [24, 42])).to eq([24, 42])
      expect(event.get("[a][0]")).to eq(24)

      expect(event.set("[a][0]", {"a "=> 99, "b" => 98})).to eq({"a "=> 99, "b" => 98})
      expect(event.get("[a][0]")).to eq({"a "=> 99, "b" => 98})

      expect(event.get("[a]")).to eq([{"a "=> 99, "b" => 98}, 42])
      expect(event.get("[a][0]")).to eq({"a "=> 99, "b" => 98})
      expect(event.get("[a][1]")).to eq(42)
      expect(event.get("[a][0][b]")).to eq(98)
    end
  end
end

