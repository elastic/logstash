require "spec_helper"
require "logstash/util/fieldreference"

describe LogStash::Util::FieldReference, :if => true do

  context "using simple accessor" do

    it "should retrieve value" do
      str = "hello"
      m = eval(subject.compile(str))
      data = { "hello" => "world" }
      expect(m.call(data)).to eq(data[str])
    end

    it "should handle delete in block" do
      str = "simple"
      m = eval(subject.compile(str))
      data = { "simple" => "things" }
      m.call(data) { |obj, key| obj.delete(key) }
      expect(data).to be_empty
    end

    it "should handle assignment in block" do
      str = "simple"
      m = eval(subject.compile(str))
      data = {}
      expect(m.call(data) { |obj, key| obj[key] = "things" }).to eq("things")
      expect(data).to eq({ "simple" => "things" })
    end

    it "should handle assignment using set" do
      str = "simple"
      data = {}
      expect(subject.set(str, "things", data)).to eq("things")
      expect(data).to eq({ "simple" => "things" })
    end
  end

  context "using accessor path" do

    it "should retrieve shallow value" do
      str = "[hello]"
      m = eval(subject.compile(str))
      data = { "hello" =>  "world" }
      expect(m.call(data)).to eq("world")
    end

    it "should retrieve deep value" do
      str = "[hello][world]"
      m = eval(subject.compile(str))
      data = { "hello" => { "world" => "foo", "bar" => "baz" } }
      expect(m.call(data)).to eq(data["hello"]["world"])
    end

    it "should handle delete in block" do
      str = "[hello][world]"
      m = eval(subject.compile(str))
      data = { "hello" => { "world" => "foo", "bar" => "baz" } }
      m.call(data) { |obj, key| obj.delete(key) }

      # Make sure the "world" key is removed.
      expect(data["hello"]).to eq({ "bar" => "baz" })
    end

    it "should not handle assignment in block" do
      str = "[hello][world]"
      m = eval(subject.compile(str))
      data = {}
      expect(m.call(data) { |obj, key| obj[key] = "things" }).to be_nil
      expect(data).to be_empty
    end

    it "should set shallow value" do
      str = "[hello]"
      data = {}
      expect(subject.set(str, "foo", data)).to eq("foo")
      expect(data).to eq({ "hello" => "foo" })
    end

    it "should set deep value" do
      str = "[hello][world]"
      data = {}
      expect(subject.set(str, "foo", data)).to eq("foo")
      expect(data).to eq({ "hello" => { "world" => "foo" } })
    end

    it "should retrieve array item" do
      data = { "hello" => { "world" => ["a", "b"], "bar" => "baz" } }
      m = eval(subject.compile("[hello][world][0]"))
      expect(m.call(data)).to eq(data["hello"]["world"][0])

      m = eval(subject.compile("[hello][world][1]"))
      expect(m.call(data)).to eq(data["hello"]["world"][1])
    end
  end
end
