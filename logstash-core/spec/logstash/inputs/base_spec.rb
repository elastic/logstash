# encoding: utf-8
require "spec_helper"
require "logstash/inputs/base"
require "support/shared_contexts"

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

  context "execution context" do
    include_context "execution_context"

    let(:klass) { LogStash::Inputs::NOOP }

    subject(:instance) { klass.new({}) }

    it "allow to set the context" do
      expect(instance.execution_context).to be_nil
      instance.execution_context = execution_context

      expect(instance.execution_context).to eq(execution_context)
    end

    it "propagate the context to the codec" do
      expect(instance.codec.execution_context).to be_nil
      instance.execution_context = execution_context

      expect(instance.codec.execution_context).to eq(execution_context)
    end
  end

  describe "cloning" do
    let(:input) do
      LogStash::Inputs::NOOP.new("add_field" => {"field" => ["value1", "value2"], "field2" => "value"})
    end

    let(:cloned) do
      input.clone
    end

    it "should clone the codec when cloned" do
      expect(input.codec).not_to eq(cloned.codec)
    end

    it "should preserve codec params" do
      expect(input.codec.params).to eq(cloned.codec.params)
    end
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
