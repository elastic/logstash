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

    it "should set value" do
      str = "simple"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.set(str, "things") } == "things"
      insist { data } == { "simple" => "things" }
    end
  end

  context "using field path" do

    it "should get shallow value of word key" do
      str = "[hello]"
      data = { "hello" =>  "world" }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == "world"
    end

    it "should get shallow value of key with spaces" do
      str = "[hel lo]"
      data = { "hel lo" =>  "world" }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == "world"
    end

    it "should get shallow value of numeric key string" do
      str = "[1]"
      data = { "1" =>  "world" }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == "world"
    end

    it "should get deep value" do
      str = "[hello][world]"
      data = { "hello" => { "world" => "foo", "bar" => "baz" } }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get(str) } == data["hello"]["world"]
    end

    it "should get deep value" do
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

    it "should set shallow value" do
      str = "[hello]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.set(str, "foo") } == "foo"
      insist { data } == { "hello" => "foo" }
    end

    it "should set deep value" do
      str = "[hello][world]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.set(str, "foo") } == "foo"
      insist { data } == { "hello" => { "world" => "foo" } }
    end

    it "should retrieve array item" do
      data = { "hello" => { "world" => ["a", "b"], "bar" => "baz" } }
      accessors = LogStash::Util::Accessors.new(data)
      insist { accessors.get("[hello][world][0]") } == data["hello"]["world"][0]
      insist { accessors.get("[hello][world][1]") } == data["hello"]["world"][1]
    end
  end
end
