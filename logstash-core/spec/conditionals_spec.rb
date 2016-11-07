# encoding: utf-8
require 'spec_helper'

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

  before do
    LogStash::PLUGIN_REGISTRY.add(:output, "dummynull", DummyNullOutput)
  end

  describe "simple" do
    config <<-CONFIG
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

    agent do
      #LOGSTASH-2288, should not fail raising an exception
    end
  end
end

describe "conditionals in filter" do
  extend ConditionalFanciness

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

    sample({"foo" => "bar"}) do
      expect(subject.get("always")).to eq("awesome")
      expect(subject.get("hello")).to eq("world")
      expect(subject.get("fancy")).to be_nil
      expect(subject.get("free")).to be_nil
    end

    sample({"notfoo" => "bar"}) do
      expect(subject.get("always")).to eq("awesome")
      expect(subject.get("hello")).to be_nil
      expect(subject.get("fancy")).to be_nil
      expect(subject.get("free")).to eq("hugs")
    end

    sample({"bar" => "baz"}) do
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

    sample("foo" => "bar", "nest" => 124) do
      expect(subject.get("always")).to be_nil
      expect(subject.get("hello")).to be_nil
      expect(subject.get("fancy")).to be_nil
      expect(subject.get("free")).to be_nil
    end

    sample("foo" => "bar", "nest" => 123) do
      expect(subject.get("always")).to eq("awesome")
      expect(subject.get("hello")).to eq("world")
      expect(subject.get("fancy")).to be_nil
      expect(subject.get("free")).to be_nil
    end

    sample("notfoo" => "bar", "nest" => 123) do
      expect(subject.get("always")).to eq("awesome")
      expect(subject.get("hello")).to be_nil
      expect(subject.get("fancy")).to be_nil
      expect(subject.get("free")).to eq("hugs")
    end

    sample("bar" => "baz", "nest" => 123) do
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

    sample("foo" => 123, "bar" => 123) do
      expect(subject.get("tags") ).to include("woot")
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

    sample("foo" => "foo", "foobar" => "foobar", "greeting" => "hello world") do
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

    sample("foo" => "foo", "somelist" => [ "one", "two" ], "foobar" => "foobar", "greeting" => "hello world", "tags" => [ "fancypantsy" ]) do
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
      sample("sample") { expect(subject.get("tags") ).to include("success") }
      sample("different") { expect(subject.get("tags") ).to include("failure") }
    end

    conditional "[message] != 'sample'" do
      sample("sample") { expect(subject.get("tags") ).to include("failure") }
      sample("different") { expect(subject.get("tags") ).to include("success") }
    end

    conditional "[message] < 'sample'" do
      sample("apple") { expect(subject.get("tags") ).to include("success") }
      sample("zebra") { expect(subject.get("tags") ).to include("failure") }
    end

    conditional "[message] > 'sample'" do
      sample("zebra") { expect(subject.get("tags") ).to include("success") }
      sample("apple") { expect(subject.get("tags") ).to include("failure") }
    end

    conditional "[message] <= 'sample'" do
      sample("apple") { expect(subject.get("tags") ).to include("success") }
      sample("zebra") { expect(subject.get("tags") ).to include("failure") }
      sample("sample") { expect(subject.get("tags") ).to include("success") }
    end

    conditional "[message] >= 'sample'" do
      sample("zebra") { expect(subject.get("tags") ).to include("success") }
      sample("sample") { expect(subject.get("tags") ).to include("success") }
      sample("apple") { expect(subject.get("tags") ).to include("failure") }
    end

    conditional "[message] =~ /sample/" do
      sample("apple") { expect(subject.get("tags") ).to include("failure") }
      sample("sample") { expect(subject.get("tags") ).to include("success") }
      sample("some sample") { expect(subject.get("tags") ).to include("success") }
    end

    conditional "[message] !~ /sample/" do
      sample("apple") { expect(subject.get("tags")).to include("success") }
      sample("sample") { expect(subject.get("tags")).to include("failure") }
      sample("some sample") { expect(subject.get("tags")).to include("failure") }
    end

  end

  describe "negated expressions" do
    conditional "!([message] == 'sample')" do
      sample("sample") { expect(subject.get("tags")).not_to include("success") }
      sample("different") { expect(subject.get("tags")).not_to include("failure") }
    end

    conditional "!([message] != 'sample')" do
      sample("sample") { expect(subject.get("tags")).not_to include("failure") }
      sample("different") { expect(subject.get("tags")).not_to include("success") }
    end

    conditional "!([message] < 'sample')" do
      sample("apple") { expect(subject.get("tags")).not_to include("success") }
      sample("zebra") { expect(subject.get("tags")).not_to include("failure") }
    end

    conditional "!([message] > 'sample')" do
      sample("zebra") { expect(subject.get("tags")).not_to include("success") }
      sample("apple") { expect(subject.get("tags")).not_to include("failure") }
    end

    conditional "!([message] <= 'sample')" do
      sample("apple") { expect(subject.get("tags")).not_to include("success") }
      sample("zebra") { expect(subject.get("tags")).not_to include("failure") }
      sample("sample") { expect(subject.get("tags")).not_to include("success") }
    end

    conditional "!([message] >= 'sample')" do
      sample("zebra") { expect(subject.get("tags")).not_to include("success") }
      sample("sample") { expect(subject.get("tags")).not_to include("success") }
      sample("apple") { expect(subject.get("tags")).not_to include("failure") }
    end

    conditional "!([message] =~ /sample/)" do
      sample("apple") { expect(subject.get("tags")).not_to include("failure") }
      sample("sample") { expect(subject.get("tags")).not_to include("success") }
      sample("some sample") { expect(subject.get("tags")).not_to include("success") }
    end

    conditional "!([message] !~ /sample/)" do
      sample("apple") { expect(subject.get("tags")).not_to include("success") }
      sample("sample") { expect(subject.get("tags")).not_to include("failure") }
      sample("some sample") { expect(subject.get("tags")).not_to include("failure") }
    end

  end

  describe "value as an expression" do
    # testing that a field has a value should be true.
    conditional "[message]" do
      sample("apple") { expect(subject.get("tags")).to include("success") }
      sample("sample") { expect(subject.get("tags")).to include("success") }
      sample("some sample") { expect(subject.get("tags")).to include("success") }
    end

    # testing that a missing field has a value should be false.
    conditional "[missing]" do
      sample("apple") { expect(subject.get("tags")).to include("failure") }
      sample("sample") { expect(subject.get("tags")).to include("failure") }
      sample("some sample") { expect(subject.get("tags")).to include("failure") }
    end
  end

  describe "logic operators" do
    describe "and" do
      conditional "[message] and [message]" do
        sample("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "[message] and ![message]" do
        sample("whatever") { expect(subject.get("tags")).to include("failure") }
      end
      conditional "![message] and [message]" do
        sample("whatever") { expect(subject.get("tags")).to include("failure") }
      end
      conditional "![message] and ![message]" do
        sample("whatever") { expect(subject.get("tags")).to include("failure") }
      end
    end

    describe "or" do
      conditional "[message] or [message]" do
        sample("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "[message] or ![message]" do
        sample("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "![message] or [message]" do
        sample("whatever") { expect(subject.get("tags")).to include("success") }
      end
      conditional "![message] or ![message]" do
        sample("whatever") { expect(subject.get("tags")).to include("failure") }
      end
    end
  end

  describe "field references" do
    conditional "[field with space]" do
      sample("field with space" => "hurray") do
        expect(subject.get("tags")).to include("success")
      end
    end

    conditional "[field with space] == 'hurray'" do
      sample("field with space" => "hurray") do
        expect(subject.get("tags")).to include("success")
      end
    end

    conditional "[nested field][reference with][some spaces] == 'hurray'" do
      sample({"nested field" => { "reference with" => { "some spaces" => "hurray" } } }) do
        expect(subject.get("tags")).to include("success")
      end
    end
  end

  describe "new events from root" do
    config <<-CONFIG
      filter {
        if [type] == "original" {
          clone {
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

    sample({"type" => "original"}) do
      expect(subject).to be_an(Array)
      expect(subject.length).to eq(2)

      expect(subject[0].get("type")).to eq("original")
      expect(subject[0].get("cond1")).to eq("true")
      expect(subject[0].get("cond2")).to eq(nil)

      expect(subject[1].get("type")).to eq("clone")
      # expect(subject[1].get("cond1")).to eq(nil)
      # expect(subject[1].get("cond2")).to eq("true")
    end
  end

  describe "multiple new events from root" do
    config <<-CONFIG
      filter {
        if [type] == "original" {
          clone {
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

    sample({"type" => "original"}) do
      # puts subject.inspect
      expect(subject[0].get("cond1")).to eq(nil)
      expect(subject[0].get("cond2")).to eq(nil)

      expect(subject[1].get("type")).to eq("clone1")
      expect(subject[1].get("cond1")).to eq("true")
      expect(subject[1].get("cond2")).to eq(nil)

      expect(subject[2].get("type")).to eq("clone2")
      expect(subject[2].get("cond1")).to eq(nil)
      expect(subject[2].get("cond2")).to eq("true")
    end
  end
end
