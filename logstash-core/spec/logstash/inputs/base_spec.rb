# encoding: utf-8
require "spec_helper"

# use a dummy NOOP input to test Inputs::Base
class LogStash::Inputs::NOOP < LogStash::Inputs::Base
  config_name "noop"
  milestone 2

  def register; end

end

describe "LogStash::Inputs::Base#decorate" do
  it "should add tag" do
    input = LogStash::Inputs::NOOP.new("tags" => "value")
    evt = LogStash::Event.new({"type" => "noop"})
    input.instance_eval {decorate(evt)}
    expect(evt.get("tags")).to eq(["value"])
  end

  it "should add multiple tag" do
    input = LogStash::Inputs::NOOP.new("tags" => ["value1","value2"])
    evt = LogStash::Event.new({"type" => "noop"})
    input.instance_eval {decorate(evt)}
    expect(evt.get("tags")).to eq(["value1","value2"])
  end

  it "should allow duplicates  tag" do
    input = LogStash::Inputs::NOOP.new("tags" => ["value","value"])
    evt = LogStash::Event.new({"type" => "noop"})
    input.instance_eval {decorate(evt)}
    expect(evt.get("tags")).to eq(["value","value"])
  end

  it "should add tag with sprintf" do
    input = LogStash::Inputs::NOOP.new("tags" => "%{type}")
    evt = LogStash::Event.new({"type" => "noop"})
    input.instance_eval {decorate(evt)}
    expect(evt.get("tags")).to eq(["noop"])
  end

  it "should add single field" do
    input = LogStash::Inputs::NOOP.new("add_field" => {"field" => "value"})
    evt = LogStash::Event.new({"type" => "noop"})
    input.instance_eval {decorate(evt)}
    expect(evt.get("field")).to eq("value")
  end

  it "should add single field with sprintf" do
    input = LogStash::Inputs::NOOP.new("add_field" => {"%{type}" => "%{type}"})
    evt = LogStash::Event.new({"type" => "noop"})
    input.instance_eval {decorate(evt)}
    expect(evt.get("noop")).to eq("noop")
  end

  it "should add multiple field" do
    input = LogStash::Inputs::NOOP.new("add_field" => {"field" => ["value1", "value2"], "field2" => "value"})
    evt = LogStash::Event.new({"type" => "noop"})
    input.instance_eval {decorate(evt)}
    expect(evt.get("field")).to eq(["value1","value2"])
    expect(evt.get("field2")).to eq("value")
  end
end

describe "LogStash::Inputs::Base#fix_streaming_codecs" do
  it "should carry the charset setting along when switching" do
    require "logstash/inputs/tcp"
    require "logstash/codecs/plain"
    plain = LogStash::Codecs::Plain.new("charset" => "CP1252")
    tcp = LogStash::Inputs::Tcp.new("codec" => plain, "port" => 3333)
    tcp.instance_eval { fix_streaming_codecs }
    expect(tcp.codec.charset).to eq("CP1252")
  end
end
