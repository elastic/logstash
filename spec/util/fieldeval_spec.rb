require "test_utils"
require "logstash/util/fieldreference"

describe LogStash::Util::FieldReference, :if => true do

  context "using simple accessor" do

    it "should retrieve value" do
      str = "hello"
      m = eval(subject.compile(str))
      data = { "hello" => "world" }
      insist { m.call(data) } == data[str]
    end

    it "should handle delete in block" do
      str = "simple"
      m = eval(subject.compile(str))
      data = { "simple" => "things" }
      m.call(data) { |obj, key| obj.delete(key) }
      insist { data }.empty?
    end

    it "should handle assignment in block" do
      str = "simple"
      m = eval(subject.compile(str))
      data = {}
      insist { m.call(data) { |obj, key| obj[key] = "things" }} == "things"
      insist { data } == { "simple" => "things" }
    end

    it "should handle assignment using set" do
      str = "simple"
      data = {}
      insist { subject.set(str, "things", data) } == "things"
      insist { data } == { "simple" => "things" }
    end
  end

  context "using accessor path" do

    it "should retrieve shallow value" do
      str = "[hello]"
      m = eval(subject.compile(str))
      data = { "hello" =>  "world" }
      insist { m.call(data) } == "world"
    end

    it "should retrieve deep value" do
      str = "[hello][world]"
      m = eval(subject.compile(str))
      data = { "hello" => { "world" => "foo", "bar" => "baz" } }
      insist { m.call(data) } == data["hello"]["world"]
    end

    it "should handle delete in block" do
      str = "[hello][world]"
      m = eval(subject.compile(str))
      data = { "hello" => { "world" => "foo", "bar" => "baz" } }
      m.call(data) { |obj, key| obj.delete(key) }

      # Make sure the "world" key is removed.
      insist { data["hello"] } == { "bar" => "baz" }
    end

    it "should not handle assignment in block" do
      str = "[hello][world]"
      m = eval(subject.compile(str))
      data = {}
      insist { m.call(data) { |obj, key| obj[key] = "things" }}.nil?
      insist { data } == { }
    end

    it "should set shallow value" do
      str = "[hello]"
      data = {}
      insist { subject.set(str, "foo", data) } == "foo"
      insist { data } == { "hello" => "foo" }
    end

    it "should set deep value" do
      str = "[hello][world]"
      data = {}
      insist { subject.set(str, "foo", data) } == "foo"
      insist { data } == { "hello" => { "world" => "foo" } }
    end

    it "should retrieve array item" do
      data = { "hello" => { "world" => ["a", "b"], "bar" => "baz" } }
      m = eval(subject.compile("[hello][world][0]"))
      insist { m.call(data) } == data["hello"]["world"][0]

      m = eval(subject.compile("[hello][world][1]"))
      insist { m.call(data) } == data["hello"]["world"][1]
    end
  end
end
