# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

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
    input = LogStash::Inputs::NOOP.new("tags" => ["value1", "value2"])
    evt = LogStash::Event.new({"type" => "noop"})
    input.instance_eval {decorate(evt)}
    expect(evt.get("tags")).to eq(["value1", "value2"])
  end

  it "should allow duplicates  tag" do
    input = LogStash::Inputs::NOOP.new("tags" => ["value", "value"])
    evt = LogStash::Event.new({"type" => "noop"})
    input.instance_eval {decorate(evt)}
    expect(evt.get("tags")).to eq(["value", "value"])
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
    expect(evt.get("field")).to eq(["value1", "value2"])
    expect(evt.get("field2")).to eq("value")
  end

  context "execution context" do
    include_context "execution_context"

    let(:klass) { LogStash::Inputs::NOOP }

    subject(:instance) { klass.new({}) }

    context 'execution_context=' do
      let(:deprecation_logger_stub) { double('DeprecationLogger').as_null_object }
      before(:each) do
        allow(klass).to receive(:deprecation_logger).and_return(deprecation_logger_stub)
      end

      it "allow to set the context" do
        new_ctx = execution_context.dup
        subject.execution_context = new_ctx
        expect(subject.execution_context).to be(new_ctx)
      end

      it "propagate the context to the codec" do
        new_ctx = execution_context.dup
        expect(instance.codec.execution_context).to_not be(new_ctx)
        instance.execution_context = new_ctx

        expect(instance.execution_context).to be(new_ctx)
        expect(instance.codec.execution_context).to be(new_ctx)
      end

      it 'emits a deprecation warning' do
        expect(deprecation_logger_stub).to receive(:deprecated) do |message|
          expect(message).to match(/execution_context=/)
        end

        instance.execution_context = execution_context
      end
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

  it "should switch plain codec to line" do
    require "logstash/inputs/tcp"
    require "logstash/codecs/plain"
    require "logstash/codecs/line"

    # it is important to use "codec" => "plain" here and not the LogStash::Codecs::Plain instance so that
    # the config parsing wrap the codec into the delagator which was causing the codec identification bug
    # per https://github.com/elastic/logstash/issues/11140
    tcp = LogStash::Inputs::Tcp.new("codec" => "plain", "port" => 0)
    tcp.register

    expect(tcp.codec.class.name).to eq("LogStash::Codecs::Line")
  end

  it "should switch json codec to json_lines" do
    require "logstash/inputs/tcp"
    require "logstash/codecs/plain"
    require "logstash/codecs/line"

    # it is important to use "codec" => "json" here and not the LogStash::Codecs::Plain instance so that
    # the config parsing wrap the codec into the delagator which was causing the codec identification bug
    # per https://github.com/elastic/logstash/issues/11140
    tcp = LogStash::Inputs::Tcp.new("codec" => "json", "port" => 0)
    tcp.register

    expect(tcp.codec.class.name).to eq("LogStash::Codecs::JSONLines")
  end
end
