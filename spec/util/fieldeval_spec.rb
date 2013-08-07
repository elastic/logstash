require "logstash/util/fieldeval"

describe LogStash::Util::HashEval do
  it "xxx" do
    str = "[hello][world]"
    #puts subject.compile(str)
  end
end

describe LogStash::Util::HashEval, :if => true do
  it "should permit simple key names" do
    str = "hello"
    m = eval(subject.compile(str))
    data = { "hello" => "world" }
    insist { m.call(data) } == data[str]
  end

  it "should permit [key][access]" do
    str = "[hello][world]"
    m = eval(subject.compile(str))
    data = { "hello" => { "world" => "foo", "bar" => "baz" } }
    insist { m.call(data) } == data["hello"]["world"]
  end
  it "should permit [key][access]" do
    str = "[hello][world]"
    m = eval(subject.compile(str))
    data = { "hello" => { "world" => "foo", "bar" => "baz" } }
    insist { m.call(data) } == data["hello"]["world"]
  end
  
  it "should permit blocks" do
    str = "[hello][world]"
    code = subject.compile(str)
    m = eval(subject.compile(str))
    data = { "hello" => { "world" => "foo", "bar" => "baz" } }
    m.call(data) { |obj, key| obj.delete(key) }

    # Make sure the "world" key is removed.
    insist { data["hello"] } == { "bar" => "baz" }
  end
end
