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

require 'spec_helper'
require 'support/pipeline/pipeline_helpers'

module ConditionalFanciness
  def description
    return self.metadata[:description]
  end

  def conditional(expression, &block)
    describe(expression) do
      config <<-CONFIG
        filter {
          if #{expression} {
            mutate { add_tag => "success" }
          } else {
            mutate { add_tag => "failure" }
          }
        }
      CONFIG
      instance_eval(&block)
    end
  end
end

describe "conditionals in output" do
  extend ConditionalFanciness

  class DummyNullOutput < LogStash::Outputs::Base
    config_name "dummynull"

    def register
    end

    def multi_receive(events)
    end
  end

  describe "simple" do
    let(:config) do <<-CONFIG
    input {
      generator {
        message => '{"foo":{"bar"},"baz": "quux"}'
        count => 1
      }
    }
    output {
      if [foo] == "bar" {
        dummynull { }
      }
    }
    CONFIG
    end

    let(:pipeline) do
      settings = ::LogStash::SETTINGS.clone
      config_part = org.logstash.common.SourceWithMetadata.new("config_string", "config_string", config)
      pipeline_config = LogStash::Config::PipelineConfig.new(LogStash::Config::Source::Local, :main, config_part, settings)
      LogStash::JavaPipeline.new(pipeline_config)
    end

    before do
      LogStash::PLUGIN_REGISTRY.add(:output, "dummynull", DummyNullOutput)
    end

    after do
      pipeline.close
    end

    it "should not fail in pipeline run" do
      #LOGSTASH-2288, should not fail raising an exception
      pipeline.run
    end
  end
end

describe "conditionals in filter" do
  extend ConditionalFanciness
  extend PipelineHelpers

  let(:settings) do
    # settings is used by sample_one.
    # This was originally set directly in sample_one and
    # pipeline.workers was also set to 1. I am preserving
    # this setting here for the sake of minimizing change
    # but unsure if this is actually required.

    LogStash::SETTINGS.clone.tap do |s|
      s.set_value("pipeline.workers", 1)
      s.set_value("pipeline.ordered", true)
    end
  end

  describe "simple" do
    config <<-CONFIG
      filter {
        mutate { add_field => { "always" => "awesome" } }
        if [foo] == "bar" {
          mutate { add_field => { "hello" => "world" } }
        } else if [bar] == "baz" {
          mutate { add_field => { "fancy" => "pants" } }
        } else {
          mutate { add_field => { "free" => "hugs" } }
        }
      }
    CONFIG

    sample_one({"foo" => "bar"}) do
      expect(subject.get("always")).to eq("awesome")
      expect(subject.get("hello")).to eq("world")
      expect(subject.get("fancy")).to be_nil
      expect(subject.get("free")).to be_nil
    end

    sample_one({"notfoo" => "bar"}) do
      expect(subject.get("always")).to eq("awesome")
      expect(subject.get("hello")).to be_nil
      expect(subject.get("fancy")).to be_nil
      expect(subject.get("free")).to eq("hugs")
    end

    sample_one({"bar" => "baz"}) do
      expect(subject.get("always")).to eq("awesome")
      expect(subject.get("hello")).to be_nil
      expect(subject.get("fancy")).to eq("pants")
      expect(subject.get("free")).to be_nil
    end
  end

  describe "nested" do
    config <<-CONFIG
      filter {
        if [nest] == 123 {
          mutate { add_field => { "always" => "awesome" } }
          if [foo] == "bar" {
            mutate { add_field => { "hello" => "world" } }
          } else if [bar] == "baz" {
            mutate { add_field => { "fancy" => "pants" } }
          } else {
            mutate { add_field => { "free" => "hugs" } }
          }
        }
      }
    CONFIG

    sample_one("foo" => "bar", "nest" => 124) do
      expect(subject.get("always")).to be_nil
      expect(subject.get("hello")).to be_nil
      expect(subject.get("fancy")).to be_nil
      expect(subject.get("free")).to be_nil
    end

    sample_one("foo" => "bar", "nest" => 123) do
      expect(subject.get("always")).to eq("awesome")
      expect(subject.get("hello")).to eq("world")
      expect(subject.get("fancy")).to be_nil
      expect(subject.get("free")).to be_nil
    end

    sample_one("notfoo" => "bar", "nest" => 123) do
      expect(subject.get("always")).to eq("awesome")
      expect(subject.get("hello")).to be_nil
      expect(subject.get("fancy")).to be_nil
      expect(subject.get("free")).to eq("hugs")
    end

    sample_one("bar" => "baz", "nest" => 123) do
      expect(subject.get("always")).to eq("awesome")
      expect(subject.get("hello")).to be_nil
      expect(subject.get("fancy")).to eq("pants")
      expect(subject.get("free")).to be_nil
    end
  end

  describe "comparing two fields" do
    config <<-CONFIG
      filter {
        if [foo] == [bar] {
          mutate { add_tag => woot }
        }
      }
    CONFIG

    sample_one("foo" => 123, "bar" => 123) do
      expect(subject.get("tags")).to include("woot")
    end
  end

  describe "the 'in' operator" do
    config <<-CONFIG
      filter {
        if [foo] in [foobar] {
          mutate { add_tag => "field in field" }
        }
        if [foo] in "foo" {
          mutate { add_tag => "field in string" }
        }
        if "hello" in [greeting] {
          mutate { add_tag => "string in field" }
        }
        if [foo] in ["hello", "world", "foo"] {
          mutate { add_tag => "field in list" }
        }
        if [missing] in [alsomissing] {
          mutate { add_tag => "shouldnotexist" }
        }
        if !("foo" in ["hello", "world"]) {
          mutate { add_tag => "shouldexist" }
        }
      }
    CONFIG

    sample_one("foo" => "foo", "foobar" => "foobar", "greeting" => "hello world") do
      expect(subject.get("tags")).to include("field in field")
      expect(subject.get("tags")).to include("field in string")
      expect(subject.get("tags")).to include("string in field")
      expect(subject.get("tags")).to include("field in list")
      expect(subject.get("tags")).not_to include("shouldnotexist")
      expect(subject.get("tags")).to include("shouldexist")
    end
  end

  describe "the 'not in' operator" do
    config <<-CONFIG
      filter {
        if "foo" not in "baz" { mutate { add_tag => "baz" } }
        if "foo" not in "foo" { mutate { add_tag => "foo" } }
        if !("foo" not in "foo") { mutate { add_tag => "notfoo" } }
        if "foo" not in [somelist] { mutate { add_tag => "notsomelist" } }
        if "one" not in [somelist] { mutate { add_tag => "somelist" } }
        if "foo" not in [alsomissing] { mutate { add_tag => "no string in missing field" } }
      }
    CONFIG

    sample_one("foo" => "foo", "somelist" => ["one", "two"], "foobar" => "foobar", "greeting" => "hello world", "tags" => ["fancypantsy"]) do
      # verify the original exists
      expect(subject.get("tags")).to include("fancypantsy")

      expect(subject.get("tags")).to include("baz")
      expect(subject.get("tags")).not_to include("foo")
      expect(subject.get("tags")).to include("notfoo")
      expect(subject.get("tags")).to include("notsomelist")
      expect(subject.get("tags")).not_to include("somelist")
      expect(subject.get("tags")).to include("no string in missing field")
    end
  end

  describe "operators" do
    conditional "[message] == 'sample'" do
      sample_one("sample") { expect(subject.get("tags")).to include("success") }
      sample_one("different") { expect(subject.get("tags")).to include("failure") }
    end

    conditional "'sample' == [message]" do
      sample_one("sample") {expect(subject.get("tags")).to include("success")}
      sample_one("different") {expect(subject.get("tags")).to include("failure")}
    end

    conditional "'value' == 'value'" do
      sample_one("sample") {expect(subject.get("tags")).to include("success")}
    end

    conditional "'value' == 'other'" do
      sample_one("sample") {expect(subject.get("tags")).to include("failure")}
    end

    conditional "[message] != 'sample'" do
      sample_one("sample") { expect(subject.get("tags")).to include("failure") }
      sample_one("different") { expect(subject.get("tags")).to include("success") }
    end

    conditional "[message] < 'sample'" do
      sample_one("apple") { expect(subject.get("tags")).to include("success") }
      sample_one("zebra") { expect(subject.get("tags")).to include("failure") }
    end

    conditional "[message] > 'sample'" do
      sample_one("zebra") { expect(subject.get("tags")).to include("success") }
      sample_one("apple") { expect(subject.get("tags")).to include("failure") }
    end

    conditional "[message] <= 'sample'" do
      sample_one("apple") { expect(subject.get("tags")).to include("success") }
      sample_one("zebra") { expect(subject.get("tags")).to include("failure") }
      sample_one("sample") { expect(subject.get("tags")).to include("success") }
    end

    conditional "[message] >= 'sample'" do
      sample_one("zebra") { expect(subject.get("tags")).to include("success") }
      sample_one("sample") { expect(subject.get("tags")).to include("success") }
      sample_one("apple") { expect(subject.get("tags")).to include("failure") }
    end

    conditional "[message] == 5" do
      sample_one("message" => 5) {expect(subject.get("tags")).to include("success")}
      sample_one("message" => 3) {expect(subject.get("tags")).to include("failure")}
    end

    conditional "5 == [message]" do
      sample_one("message" => 5) {expect(subject.get("tags")).to include("success")}
      sample_one("message" => 3) {expect(subject.get("tags")).to include("failure")}
    end

    conditional "7 == 7" do
      sample_one("message" => 7) {expect(subject.get("tags")).to include("success")}
      sample_one("message" => 3) {expect(subject.get("tags")).to include("success")}
    end

    conditional "5 == 7" do
      sample_one("message" => 3) {expect(subject.get("tags")).to include("failure")}
      sample_one("message" => 2) {expect(subject.get("tags")).to include("failure")}
    end

    conditional "[message] != 5" do
      sample_one("message" => 5) {expect(subject.get("tags")).to include("failure")}
      sample_one("message" => 3) {expect(subject.get("tags")).to include("success")}
    end

    conditional "[message] < 5" do
      sample_one("message" => 3) {expect(subject.get("tags")).to include("success")}
      sample_one("message" => 5) {expect(subject.get("tags")).to include("failure")}
      sample_one("message" => 9) {expect(subject.get("tags")).to include("failure")}
    end

    conditional "[message] > 5" do
      sample_one("message" => 9) {expect(subject.get("tags")).to include("success")}
      sample_one("message" => 5) {expect(subject.get("tags")).to include("failure")}
      sample_one("message" => 4) {expect(subject.get("tags")).to include("failure")}
    end

    conditional "[message] <= 5" do
      sample_one("message" => 9) {expect(subject.get("tags")).to include("failure")}
      sample_one("message" => 5) {expect(subject.get("tags")).to include("success")}
      sample_one("message" => 3) {expect(subject.get("tags")).to include("success")}
    end

    conditional "[message] >= 5" do
      sample_one("message" => 5) {expect(subject.get("tags")).to include("success")}
      sample_one("message" => 7) {expect(subject.get("tags")).to include("success")}
      sample_one("message" => 3) {expect(subject.get("tags")).to include("failure")}
    end

    conditional "[message] =~ /sample/" do
      sample_one("apple") { expect(subject.get("tags")).to include("failure") }
      sample_one("sample") { expect(subject.get("tags")).to include("success") }
      sample_one("some sample") { expect(subject.get("tags")).to include("success") }
    end

    conditional "[message] !~ /sample/" do
      sample_one("apple") { expect(subject.get("tags")).to include("success") }
      sample_one("sample") { expect(subject.get("tags")).to include("failure") }
      sample_one("some sample") { expect(subject.get("tags")).to include("failure") }
    end
  end

  describe "negated expressions" do
    conditional "!([message] == 'sample')" do
      sample_one("sample") { expect(subject.get("tags")).not_to include("success") }
      sample_one("different") { expect(subject.get("tags")).not_to include("failure") }
    end

    conditional "!([message] != 'sample')" do
      sample_one("sample") { expect(subject.get("tags")).not_to include("failure") }
      sample_one("different") { expect(subject.get("tags")).not_to include("success") }
    end

    conditional "!([message] < 'sample')" do
      sample_one("apple") { expect(subject.get("tags")).not_to include("success") }
      sample_one("zebra") { expect(subject.get("tags")).not_to include("failure") }
    end

    conditional "!([message] > 'sample')" do
      sample_one("zebra") { expect(subject.get("tags")).not_to include("success") }
      sample_one("apple") { expect(subject.get("tags")).not_to include("failure") }
    end

    conditional "!([message] <= 'sample')" do
      sample_one("apple") { expect(subject.get("tags")).not_to include("success") }
      sample_one("zebra") { expect(subject.get("tags")).not_to include("failure") }
      sample_one("sample") { expect(subject.get("tags")).not_to include("success")}
    end

    conditional "!([message] >= 'sample')" do
      sample_one("zebra") { expect(subject.get("tags")).not_to include("success") }
      sample_one("sample") { expect(subject.get("tags")).not_to include("success") }
      sample_one("apple") { expect(subject.get("tags")).not_to include("failure") }
    end

    conditional "!([message] =~ /sample/)" do
      sample_one("apple") { expect(subject.get("tags")).not_to include("failure") }
      sample_one("sample") { expect(subject.get("tags")).not_to include("success") }
      sample_one("some sample") { expect(subject.get("tags")).not_to include("success") }
    end

    conditional "!([message] !~ /sample/)" do
      sample_one("apple") { expect(subject.get("tags")).not_to include("success") }
      sample_one("sample") { expect(subject.get("tags")).not_to include("failure") }
      sample_one("some sample") { expect(subject.get("tags")).not_to include("failure") }
    end
  end

  describe "value as an expression" do
    # testing that a field has a value should be true.
    conditional "[message]" do
      sample_one("apple") { expect(subject.get("tags")).to include("success") }
      sample_one("sample") { expect(subject.get("tags")).to include("success") }
      sample_one("some sample") { expect(subject.get("tags")).to include("success") }
    end

    # testing that a missing field has a value should be false.
    conditional "[missing]" do
      sample_one("apple") { expect(subject.get("tags")).to include("failure") }
      sample_one("sample") { expect(subject.get("tags")).to include("failure") }
      sample_one("some sample") { expect(subject.get("tags")).to include("failure") }
    end
  end

  describe "logic operators" do
    describe "and" do
      conditional "[message] and [message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "[message] and ![message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("failure") }
      end
      conditional "![message] and [message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("failure") }
      end
      conditional "![message] and ![message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("failure") }
      end
    end

    describe "nand" do
      conditional "[message] nand [message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("failure") }
      end
      conditional "[message] nand ![message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "![message] nand [message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "![message] nand ![message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("success") }
      end
    end

    describe "xor" do
      conditional "[message] xor [message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("failure") }
      end
      conditional "[message] xor ![message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "![message] xor [message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "![message] xor ![message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("failure") }
      end
    end

    describe "or" do
      conditional "[message] or [message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "[message] or ![message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "![message] or [message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "![message] or ![message]" do
        sample_one("whatever") { expect(subject.get("tags")).to include("failure") }
      end
    end
  end

  describe "field references" do
    conditional "[field with space]" do
      sample_one("field with space" => "hurray") do
        expect(subject.get("tags")).to include("success")
      end
    end

    conditional "[field with space] == 'hurray'" do
      sample_one("field with space" => "hurray") do
        expect(subject.get("tags")).to include("success")
      end
    end

    conditional "[nested field][reference with][some spaces] == 'hurray'" do
      sample_one({"nested field" => { "reference with" => { "some spaces" => "hurray" } } }) do
        expect(subject.get("tags")).to include("success")
      end
    end
  end

  describe "new events from root" do
    config <<-CONFIG
      filter {
        if [type] == "original" {
          clone {
            ecs_compatibility => disabled # rely on legacy clone plugin behaviour
            clones => ["clone"]
          }
        }
        if [type] == "original" {
          mutate { add_field => { "cond1" => "true" } }
        } else {
          mutate { add_field => { "cond2" => "true" } }
        }
      }
    CONFIG

    sample_one({"type" => "original"}) do
      expect(subject).to be_an(Array)
      expect(subject.length).to eq(2)
      original_event = subject[0]
      expect(original_event.get("type")).to eq("original")
      expect(original_event.get("cond1")).to eq("true")
      expect(original_event.get("cond2")).to eq(nil)
      cloned_event = subject[1]
      expect(cloned_event.get("cond1")).to eq(nil)
      expect(cloned_event.get("cond2")).to eq("true")
      expect(cloned_event.get("type")).to eq("clone")
    end
  end

  describe "multiple new events from root" do
    config <<-CONFIG
      filter {
        if [type] == "original" {
          clone {
            ecs_compatibility => disabled # rely on legacy clone plugin behaviour
            clones => ["clone1", "clone2"]
          }
        }
        if [type] == "clone1" {
          mutate { add_field => { "cond1" => "true" } }
        } else if [type] == "clone2" {
          mutate { add_field => { "cond2" => "true" } }
        }
      }
    CONFIG

    sample_one({"type" => "original"}) do
      clone_event_1 = subject[0]
      expect(clone_event_1.get("type")).to eq("clone1")
      expect(clone_event_1.get("cond1")).to eq("true")
      expect(clone_event_1.get("cond2")).to eq(nil)
      clone_event_2 = subject[1]
      expect(clone_event_2.get("type")).to eq("clone2")
      expect(clone_event_2.get("cond1")).to eq(nil)
      expect(clone_event_2.get("cond2")).to eq("true")
      original_event = subject[2]
      expect(original_event.get("type")).to eq("original")
      expect(original_event.get("cond1")).to eq(nil)
      expect(original_event.get("cond2")).to eq(nil)
    end
  end

  describe "complex case" do
    config <<-CONFIG
      filter {
        if ("foo" in [tags]) {
          mutate { id => addbar add_tag => bar }

          if ("bar" in [tags]) {
            mutate { id => addbaz  add_tag => baz }
          }

          if ("baz" in [tags]) {
            mutate { id => addbot add_tag => bot }

            if ("bot" in [tags]) {
              mutate { id => addbonk add_tag => bonk }
            }
          }
        }

        if ("bot" in [tags]) {
          mutate { id => addwat add_tag => wat }
        }

        mutate { id => addprev add_tag => prev }

        mutate { id => addfinal add_tag => final }

      }
    CONFIG

    sample_one("tags" => ["bot"]) do
      tags = subject.get("tags")
      expect(tags[0]).to eq("bot")
      expect(tags[1]).to eq("wat")
      expect(tags[2]).to eq("prev")
      expect(tags[3]).to eq("final")
    end

    sample_one("tags" => ["foo"]) do
      tags = subject.get("tags")
      expect(tags[0]).to eq("foo")
      expect(tags[1]).to eq("bar")
      expect(tags[2]).to eq("baz")
      expect(tags[3]).to eq("bot")
      expect(tags[4]).to eq("bonk")
      expect(tags[5]).to eq("wat")
      expect(tags[6]).to eq("prev")
      expect(tags[7]).to eq("final")
    end

    sample_one("type" => "original") do
      tags = subject.get("tags")
      expect(tags[0]).to eq("prev")
      expect(tags[1]).to eq("final")
    end
  end
end
