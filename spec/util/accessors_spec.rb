# encoding: utf-8

require "test_utils"
require "logstash/util/accessors"

describe LogStash::Util::Accessors, :if => true do

  context "using simple field" do

    it "should get value of word key" do
      str = "hello"
      data = { "hello" => "world" }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == data[str]
    end

    it "should get value of key with spaces" do
      str = "hel lo"
      data = { "hel lo" => "world" }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == data[str]
    end

    it "should get value of numeric key string" do
      str = "1"
      data = { "1" => "world" }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == data[str]
    end

    it "should handle delete" do
      str = "simple"
      data = { "simple" => "things" }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.del(str) } == "things"
      insist { data }.empty?
    end

    it "should set string value" do
      str = "simple"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.set(str, "things") } == "things"
      insist { data } == { "simple" => "things" }
    end

    it "should set array value" do
      str = "simple"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.set(str, ["foo", "bar"]) } == ["foo", "bar"]
      insist { data } == { "simple" => ["foo", "bar"]}
    end
  end

  context "using field path" do

    it "should get shallow string value of word key" do
      str = "[hello]"
      data = { "hello" =>  "world" }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == "world"
    end

    it "should get shallow string value of key with spaces" do
      str = "[hel lo]"
      data = { "hel lo" =>  "world" }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == "world"
    end

    it "should get shallow string value of numeric key string" do
      str = "[1]"
      data = { "1" =>  "world" }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == "world"
    end

    it "should get deep string value" do
      str = "[hello][world]"
      data = { "hello" => { "world" => "foo", "bar" => "baz" } }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == data["hello"]["world"]
    end

    it "should get deep string value" do
      str = "[hello][world]"
      data = { "hello" => { "world" => "foo", "bar" => "baz" } }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == data["hello"]["world"]
    end

    it "should handle delete" do
      str = "[hello][world]"
      data = { "hello" => { "world" => "foo", "bar" => "baz" } }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.del(str) } ==  "foo"

      # Make sure the "world" key is removed.
      insist { data["hello"] } == { "bar" => "baz" }
    end

    it "should set shallow string value" do
      str = "[hello]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.set(str, "foo") } == "foo"
      insist { data } == { "hello" => "foo" }
    end

    it "should strict_set shallow string value" do
      str = "[hello]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.strict_set(str, "foo") } == "foo"
      insist { data } == { "hello" => "foo" }
    end

    it "should set deep string value" do
      str = "[hello][world]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.set(str, "foo") } == "foo"
      insist { data } == { "hello" => { "world" => "foo" } }
    end

    it "should set deep array value" do
      str = "[hello][world]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.set(str, ["foo", "bar"]) } == ["foo", "bar"]
      insist { data } == { "hello" => { "world" => ["foo", "bar"] } }
    end

    it "should strict_set deep array value" do
      str = "[hello][world]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.strict_set(str, ["foo", "bar"]) } == ["foo", "bar"]
      insist { data } == { "hello" => { "world" => ["foo", "bar"] } }
    end

    it "should retrieve array item" do
      data = { "hello" => { "world" => ["a", "b"], "bar" => "baz" } }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get("[hello][world][0]") } == data["hello"]["world"][0]
      insist { accessors.get("[hello][world][1]") } == data["hello"]["world"][1]
    end

    it "should retrieve array item containing hash" do
      data = { "hello" => { "world" => [ { "a" => 123 }, { "b" => 345 } ], "bar" => "baz" } }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get("[hello][world][0][a]") } == data["hello"]["world"][0]["a"]
      insist { accessors.get("[hello][world][1][b]") } == data["hello"]["world"][1]["b"]
    end
  end

  context "using invalid encoding" do
    it "strinct_set should raise on non UTF-8 string encoding" do
      str = "[hello]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      expect { accessors.strict_set(str, "foo".encode("US-ASCII")) }.to raise_error
    end

    it "strinct_set should raise on non UTF-8 string encoding in array" do
      str = "[hello]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      expect { accessors.strict_set(str, ["foo", "bar".encode("US-ASCII")]) }.to raise_error
    end

    it "strinct_set should raise on invalid UTF-8 string encoding" do
      str = "[hello]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      expect { accessors.strict_set(str, "foo \xED\xB9\x81\xC3") }.to raise_error
    end

    it "strinct_set should raise on invalid UTF-8 string encoding in array" do
      str = "[hello]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      expect { accessors.strict_set(str, ["foo", "bar \xED\xB9\x81\xC3"]) }.to raise_error
    end
  end
end
