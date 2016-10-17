# encoding: utf-8

require "spec_helper"
require "logstash/util"
require "logstash/event"
require "json"
require "java"

TIMESTAMP = "@timestamp"

describe LogStash::Event do
  context "to_json" do
    it "should serialize simple values" do
      e = LogStash::Event.new({"foo" => "bar", "bar" => 1, "baz" => 1.0, TIMESTAMP => "2015-05-28T23:02:05.350Z"})
      expect(JSON.parse(e.to_json)).to eq(JSON.parse("{\"foo\":\"bar\",\"bar\":1,\"baz\":1.0,\"@timestamp\":\"2015-05-28T23:02:05.350Z\",\"@version\":\"1\"}"))
    end

    it "should serialize deep hash values" do
      e = LogStash::Event.new({"foo" => {"bar" => 1, "baz" => 1.0, "biz" => "boz"}, TIMESTAMP => "2015-05-28T23:02:05.350Z"})
      expect(JSON.parse(e.to_json)).to eq(JSON.parse("{\"foo\":{\"bar\":1,\"baz\":1.0,\"biz\":\"boz\"},\"@timestamp\":\"2015-05-28T23:02:05.350Z\",\"@version\":\"1\"}"))
    end

    it "should serialize deep array values" do
      e = LogStash::Event.new({"foo" => ["bar", 1, 1.0], TIMESTAMP => "2015-05-28T23:02:05.350Z"})
      expect(JSON.parse(e.to_json)).to eq(JSON.parse("{\"foo\":[\"bar\",1,1.0],\"@timestamp\":\"2015-05-28T23:02:05.350Z\",\"@version\":\"1\"}"))
    end

    it "should serialize deep hash from field reference assignments" do
      e = LogStash::Event.new({TIMESTAMP => "2015-05-28T23:02:05.350Z"})
      e.set("foo", "bar")
      e.set("bar", 1)
      e.set("baz", 1.0)
      e.set("[fancy][pants][socks]", "shoes")
      expect(JSON.parse(e.to_json)).to eq(JSON.parse("{\"@timestamp\":\"2015-05-28T23:02:05.350Z\",\"@version\":\"1\",\"foo\":\"bar\",\"bar\":1,\"baz\":1.0,\"fancy\":{\"pants\":{\"socks\":\"shoes\"}}}"))
    end
  end

  context "#get" do
    it "should get simple values" do
      e = LogStash::Event.new({"foo" => "bar", "bar" => 1, "baz" => 1.0, TIMESTAMP => "2015-05-28T23:02:05.350Z"})
      expect(e.get("foo")).to eq("bar")
      expect(e.get("[foo]")).to eq("bar")
      expect(e.get("bar")).to eq(1)
      expect(e.get("[bar]")).to eq(1)
      expect(e.get("baz")).to eq(1.0)
      expect(e.get("[baz]")).to eq(1.0)
      expect(e.get(TIMESTAMP).to_s).to eq("2015-05-28T23:02:05.350Z")
      expect(e.get("[#{TIMESTAMP}]").to_s).to eq("2015-05-28T23:02:05.350Z")
    end

    it "should get deep hash values" do
      e = LogStash::Event.new({"foo" => {"bar" => 1, "baz" => 1.0}})
      expect(e.get("[foo][bar]")).to eq(1)
      expect(e.get("[foo][baz]")).to eq(1.0)
    end

    it "should get deep array values" do
      e = LogStash::Event.new({"foo" => ["bar", 1, 1.0]})
      expect(e.get("[foo][0]")).to eq("bar")
      expect(e.get("[foo][1]")).to eq(1)
      expect(e.get("[foo][2]")).to eq(1.0)
      expect(e.get("[foo][3]")).to be_nil
    end
  end

  context "#set" do
    it "should set simple values" do
      e = LogStash::Event.new()
      expect(e.set("foo", "bar")).to eq("bar")
      expect(e.get("foo")).to eq("bar")

      e = LogStash::Event.new({"foo" => "test"})
      expect(e.set("foo", "bar")).to eq("bar")
      expect(e.get("foo")).to eq("bar")
    end

    it "should set deep hash values" do
      e = LogStash::Event.new()
      expect(e.set("[foo][bar]", "baz")).to eq("baz")
      expect(e.get("[foo][bar]")).to eq("baz")
      expect(e.get("[foo][baz]")).to be_nil
    end

    it "should set deep array values" do
      e = LogStash::Event.new()
      expect(e.set("[foo][0]", "bar")).to eq("bar")
      expect(e.get("[foo][0]")).to eq("bar")
      expect(e.set("[foo][1]", 1)).to eq(1)
      expect(e.get("[foo][1]")).to eq(1)
      expect(e.set("[foo][2]", 1.0)).to eq(1.0)
      expect(e.get("[foo][2]")).to eq(1.0)
      expect(e.get("[foo][3]")).to be_nil
    end

    it "should add key when setting nil value" do
      e = LogStash::Event.new()
      e.set("[foo]", nil)
      expect(e.to_hash).to include("foo" => nil)
    end

    # BigDecinal is now natively converted by JRuby, see https://github.com/elastic/logstash/pull/4838
    it "should set BigDecimal" do
      e = LogStash::Event.new()
      e.set("[foo]", BigDecimal.new(1))
      expect(e.get("foo")).to be_kind_of(BigDecimal)
      expect(e.get("foo")).to eq(BigDecimal.new(1))
    end

    it "should set RubyBignum" do
      e = LogStash::Event.new()
      e.set("[foo]", -9223372036854776000)
      expect(e.get("foo")).to be_kind_of(Bignum)
      expect(e.get("foo")).to eq(-9223372036854776000)
    end

    it "should convert Time to Timestamp" do
      e = LogStash::Event.new()
      time = Time.now
      e.set("[foo]", Time.at(time.to_f))
      expect(e.get("foo")).to be_kind_of(LogStash::Timestamp)
      expect(e.get("foo").to_f).to be_within(0.1).of(time.to_f)
    end

    it "should set XXJavaProxy Jackson crafted" do
      proxy = org.logstash.Util.getMapFixtureJackson()
      # proxy is {"string": "foo", "int": 42, "float": 42.42, "array": ["bar","baz"], "hash": {"string":"quux"} }
      e = LogStash::Event.new()
      e.set("[proxy]", proxy)
      expect(e.get("[proxy][string]")).to eql("foo")
      expect(e.get("[proxy][int]")).to eql(42)
      expect(e.get("[proxy][float]")).to eql(42.42)
      expect(e.get("[proxy][array][0]")).to eql("bar")
      expect(e.get("[proxy][array][1]")).to eql("baz")
      expect(e.get("[proxy][hash][string]")).to eql("quux")
    end

    it "should set XXJavaProxy hand crafted" do
      proxy = org.logstash.Util.getMapFixtureHandcrafted()
      # proxy is {"string": "foo", "int": 42, "float": 42.42, "array": ["bar","baz"], "hash": {"string":"quux"} }
      e = LogStash::Event.new()
      e.set("[proxy]", proxy)
      expect(e.get("[proxy][string]")).to eql("foo")
      expect(e.get("[proxy][int]")).to eql(42)
      expect(e.get("[proxy][float]")).to eql(42.42)
      expect(e.get("[proxy][array][0]")).to eql("bar")
      expect(e.get("[proxy][array][1]")).to eql("baz")
      expect(e.get("[proxy][hash][string]")).to eql("quux")
    end

    it "should fail on non UTF-8 encoding" do
      # e = LogStash::Event.new
      # s1 = "\xE0 Montr\xE9al".force_encoding("ISO-8859-1")
      # expect(s1.encoding.name).to eq("ISO-8859-1")
      # expect(s1.valid_encoding?).to eq(true)
      # e.set("test", s1)
      # s2 = e.get("test")
      # expect(s2.encoding.name).to eq("UTF-8")
      # expect(s2.valid_encoding?).to eq(true)
    end
  end

  context "timestamp" do
    it "getters should present a Ruby LogStash::Timestamp" do
      e = LogStash::Event.new()
      expect(e.timestamp.class).to eq(LogStash::Timestamp)
      expect(e.get(TIMESTAMP).class).to eq(LogStash::Timestamp)
    end

    it "to_hash should inject a Ruby LogStash::Timestamp" do
      e = LogStash::Event.new()

      expect(e.to_java).to be_kind_of(Java::OrgLogstash::Event)
      expect(e.to_java.get_field(TIMESTAMP)).to be_kind_of(Java::OrgLogstash::Timestamp)

      expect(e.to_hash[TIMESTAMP]).to be_kind_of(LogStash::Timestamp)
      # now make sure the original map was not touched
      expect(e.to_java.get_field(TIMESTAMP)).to be_kind_of(Java::OrgLogstash::Timestamp)
    end

    it "should set timestamp" do
      e = LogStash::Event.new
      now = Time.now
      e.set("@timestamp", LogStash::Timestamp.at(now.to_i))
      expect(e.timestamp.to_i).to eq(now.to_i)
      expect(e.get("@timestamp").to_i).to eq(now.to_i)
    end
  end

  context "append" do
    it "should append" do
      event = LogStash::Event.new("message" => "hello world")
      event.append(LogStash::Event.new("message" => "another thing"))
      expect(event.get("message")).to eq(["hello world", "another thing"])
    end
  end

  context "tags" do
    it "should tag" do
      event = LogStash::Event.new("message" => "hello world")
      expect(event.get("tags")).to be_nil
      event.tag("foo")
      expect(event.get("tags")).to eq(["foo"])
    end
  end


  # TODO(talevy): migrate tests to Java. no reason to test logging logic in ruby when it is being
  #               done in java land.

  # context "logger" do

  #   let(:logger) { double("Logger") }

  #   before(:each) do
  #     allow(LogStash::Event).to receive(:logger).and_return(logger)
  #   end

  #   it "should set logger using a module" do
  #     expect(logger).to receive(:warn).once
  #     LogStash::Event.new(TIMESTAMP => "invalid timestamp")
  #   end

  #   it "should warn on invalid timestamp object" do
  #     expect(logger).to receive(:warn).once.with(/^Unrecognized/)
  #     LogStash::Event.new(TIMESTAMP => Array.new)
  #   end
  # end

  context "to_hash" do
    let (:source_hash) {  {"a" => 1, "b" => [1, 2, 3, {"h" => 1, "i" => "baz"}], "c" => {"d" => "foo", "e" => "bar", "f" => [4, 5, "six"]}} }
    let (:source_hash_with_matada) {  source_hash.merge({"@metadata" => {"a" => 1, "b" => 2}}) }
    subject { LogStash::Event.new(source_hash_with_matada) }

    it "should include @timestamp and @version" do
      h = subject.to_hash
      expect(h).to include("@timestamp")
      expect(h).to include("@version")
      expect(h).not_to include("@metadata")
    end

    it "should include @timestamp and @version and @metadata" do
      h = subject.to_hash_with_metadata
      expect(h).to include("@timestamp")
      expect(h).to include("@version")
      expect(h).to include("@metadata")
    end

    it "should produce valid deep Ruby hash without metadata" do
      h = subject.to_hash
      h.delete("@timestamp")
      h.delete("@version")
      expect(h).to eq(source_hash)
    end

    it "should produce valid deep Ruby hash with metadata" do
      h = subject.to_hash_with_metadata
      h.delete("@timestamp")
      h.delete("@version")
      expect(h).to eq(source_hash_with_matada)
    end
  end

  context "from_json" do
    let (:source_json) { "{\"foo\":1, \"bar\":\"baz\"}" }
    let (:blank_strings) {["", "  ",  "   "]}
    let (:bare_strings) {["aa", "  aa", "aa  "]}

    it "should produce a new event from json" do
      expect(LogStash::Event.from_json(source_json).size).to eq(1)

      event = LogStash::Event.from_json(source_json)[0]
      expect(event.get("[foo]")).to eq(1)
      expect(event.get("[bar]")).to eq("baz")
    end

    it "should ignore blank strings" do
      blank_strings.each do |s|
        expect(LogStash::Event.from_json(s).size).to eq(0)
      end
    end

    it "should raise TypeError on nil string" do
      expect{LogStash::Event.from_json(nil)}.to raise_error TypeError
    end

    it "should consistently handle nil" do
      blank_strings.each do |s|
        expect{LogStash::Event.from_json(nil)}.to raise_error
        expect{LogStash::Event.new(LogStash::Json.load(nil))}.to raise_error
      end
    end

    it "should consistently handle bare string" do
      bare_strings.each do |s|
        expect{LogStash::Event.from_json(s)}.to raise_error LogStash::Json::ParserError
        expect{LogStash::Event.new(LogStash::Json.load(s))}.to raise_error LogStash::Json::ParserError
       end
    end
  end

  context "initialize" do

    it "should accept Ruby Hash" do
      e = LogStash::Event.new({"foo" => 1, TIMESTAMP => "2015-05-28T23:02:05.350Z"})
      expect(e.get("foo")).to eq(1)
      expect(e.timestamp.to_iso8601).to eq("2015-05-28T23:02:05.350Z")
    end

    it "should accept Java Map" do
      h = Java::JavaUtil::HashMap.new
      h.put("foo", 2);
      h.put(TIMESTAMP, "2016-05-28T23:02:05.350Z");
      e = LogStash::Event.new(h)

      expect(e.get("foo")).to eq(2)
      expect(e.timestamp.to_iso8601).to eq("2016-05-28T23:02:05.350Z")
    end

  end

  context "method missing exception messages" do
    subject { LogStash::Event.new({"foo" => "bar"}) }

    it "#[] method raises a better exception message" do
      expect { subject["foo"] }.to raise_error(NoMethodError, /Direct event field references \(i\.e\. event\['field'\]\)/)
    end

    it "#[]= method raises a better exception message" do
      expect { subject["foo"] = "baz" }.to raise_error(NoMethodError, /Direct event field references \(i\.e\. event\['field'\] = 'value'\)/)
    end

    it "other missing method raises normal exception message" do
      expect { subject.baz() }.to raise_error(NoMethodError, /undefined method `baz' for/)
    end
  end
end
