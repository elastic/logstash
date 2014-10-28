require "spec_helper"

module ConditionalFanciness
  def description
    return example.metadata[:example_group][:description_args][0]
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
          stdout { }
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
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] } == "world"
      insist { subject["fancy"] }.nil?
      insist { subject["free"] }.nil?
    end

    sample({"notfoo" => "bar"}) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] }.nil?
      insist { subject["free"] } == "hugs"
    end

    sample({"bar" => "baz"}) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] } == "pants"
      insist { subject["free"] }.nil?
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
      insist { subject["always"] }.nil?
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] }.nil?
      insist { subject["free"] }.nil?
    end

    sample("foo" => "bar", "nest" => 123) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] } == "world"
      insist { subject["fancy"] }.nil?
      insist { subject["free"] }.nil?
    end

    sample("notfoo" => "bar", "nest" => 123) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] }.nil?
      insist { subject["free"] } == "hugs"
    end

    sample("bar" => "baz", "nest" => 123) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] } == "pants"
      insist { subject["free"] }.nil?
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
      insist { subject["tags"] }.include?("woot")
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
      insist { subject["tags"] }.include?("field in field")
      insist { subject["tags"] }.include?("field in string")
      insist { subject["tags"] }.include?("string in field")
      insist { subject["tags"] }.include?("field in list")
      reject { subject["tags"] }.include?("shouldnotexist")
      insist { subject["tags"] }.include?("shouldexist")
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
      insist { subject["tags"] }.include?("fancypantsy")

      insist { subject["tags"] }.include?("baz")
      reject { subject["tags"] }.include?("foo")
      insist { subject["tags"] }.include?("notfoo")
      insist { subject["tags"] }.include?("notsomelist")
      reject { subject["tags"] }.include?("somelist")
      insist { subject["tags"] }.include?("no string in missing field")
    end
  end

  describe "operators" do
    conditional "[message] == 'sample'" do
      sample("sample") { insist { subject["tags"] }.include?("success") }
      sample("different") { insist { subject["tags"] }.include?("failure") }
    end

    conditional "[message] != 'sample'" do
      sample("sample") { insist { subject["tags"] }.include?("failure") }
      sample("different") { insist { subject["tags"] }.include?("success") }
    end

    conditional "[message] < 'sample'" do
      sample("apple") { insist { subject["tags"] }.include?("success") }
      sample("zebra") { insist { subject["tags"] }.include?("failure") }
    end

    conditional "[message] > 'sample'" do
      sample("zebra") { insist { subject["tags"] }.include?("success") }
      sample("apple") { insist { subject["tags"] }.include?("failure") }
    end

    conditional "[message] <= 'sample'" do
      sample("apple") { insist { subject["tags"] }.include?("success") }
      sample("zebra") { insist { subject["tags"] }.include?("failure") }
      sample("sample") { insist { subject["tags"] }.include?("success") }
    end

    conditional "[message] >= 'sample'" do
      sample("zebra") { insist { subject["tags"] }.include?("success") }
      sample("sample") { insist { subject["tags"] }.include?("success") }
      sample("apple") { insist { subject["tags"] }.include?("failure") }
    end

    conditional "[message] =~ /sample/" do
      sample("apple") { insist { subject["tags"] }.include?("failure") }
      sample("sample") { insist { subject["tags"] }.include?("success") }
      sample("some sample") { insist { subject["tags"] }.include?("success") }
    end

    conditional "[message] !~ /sample/" do
      sample("apple") { insist { subject["tags"] }.include?("success") }
      sample("sample") { insist { subject["tags"] }.include?("failure") }
      sample("some sample") { insist { subject["tags"] }.include?("failure") }
    end

  end

  describe "negated expressions" do
    conditional "!([message] == 'sample')" do
      sample("sample") { reject { subject["tags"] }.include?("success") }
      sample("different") { reject { subject["tags"] }.include?("failure") }
    end

    conditional "!([message] != 'sample')" do
      sample("sample") { reject { subject["tags"] }.include?("failure") }
      sample("different") { reject { subject["tags"] }.include?("success") }
    end

    conditional "!([message] < 'sample')" do
      sample("apple") { reject { subject["tags"] }.include?("success") }
      sample("zebra") { reject { subject["tags"] }.include?("failure") }
    end

    conditional "!([message] > 'sample')" do
      sample("zebra") { reject { subject["tags"] }.include?("success") }
      sample("apple") { reject { subject["tags"] }.include?("failure") }
    end

    conditional "!([message] <= 'sample')" do
      sample("apple") { reject { subject["tags"] }.include?("success") }
      sample("zebra") { reject { subject["tags"] }.include?("failure") }
      sample("sample") { reject { subject["tags"] }.include?("success") }
    end

    conditional "!([message] >= 'sample')" do
      sample("zebra") { reject { subject["tags"] }.include?("success") }
      sample("sample") { reject { subject["tags"] }.include?("success") }
      sample("apple") { reject { subject["tags"] }.include?("failure") }
    end

    conditional "!([message] =~ /sample/)" do
      sample("apple") { reject { subject["tags"] }.include?("failure") }
      sample("sample") { reject { subject["tags"] }.include?("success") }
      sample("some sample") { reject { subject["tags"] }.include?("success") }
    end

    conditional "!([message] !~ /sample/)" do
      sample("apple") { reject { subject["tags"] }.include?("success") }
      sample("sample") { reject { subject["tags"] }.include?("failure") }
      sample("some sample") { reject { subject["tags"] }.include?("failure") }
    end

  end

  describe "value as an expression" do
    # testing that a field has a value should be true.
    conditional "[message]" do
      sample("apple") { insist { subject["tags"] }.include?("success") }
      sample("sample") { insist { subject["tags"] }.include?("success") }
      sample("some sample") { insist { subject["tags"] }.include?("success") }
    end

    # testing that a missing field has a value should be false.
    conditional "[missing]" do
      sample("apple") { insist { subject["tags"] }.include?("failure") }
      sample("sample") { insist { subject["tags"] }.include?("failure") }
      sample("some sample") { insist { subject["tags"] }.include?("failure") }
    end
  end

  describe "logic operators" do
    describe "and" do
      conditional "[message] and [message]" do
        sample("whatever") { insist { subject["tags"] }.include?("success") }
      end
      conditional "[message] and ![message]" do
        sample("whatever") { insist { subject["tags"] }.include?("failure") }
      end
      conditional "![message] and [message]" do
        sample("whatever") { insist { subject["tags"] }.include?("failure") }
      end
      conditional "![message] and ![message]" do
        sample("whatever") { insist { subject["tags"] }.include?("failure") }
      end
    end

    describe "or" do
      conditional "[message] or [message]" do
        sample("whatever") { insist { subject["tags"] }.include?("success") }
      end
      conditional "[message] or ![message]" do
        sample("whatever") { insist { subject["tags"] }.include?("success") }
      end
      conditional "![message] or [message]" do
        sample("whatever") { insist { subject["tags"] }.include?("success") }
      end
      conditional "![message] or ![message]" do
        sample("whatever") { insist { subject["tags"] }.include?("failure") }
      end
    end
  end

  describe "field references" do
    conditional "[field with space]" do
      sample("field with space" => "hurray") do
        insist { subject["tags"].include?("success") }
      end
    end

    conditional "[field with space] == 'hurray'" do
      sample("field with space" => "hurray") do
        insist { subject["tags"].include?("success") }
      end
    end

    conditional "[nested field][reference with][some spaces] == 'hurray'" do
      sample({"nested field" => { "reference with" => { "some spaces" => "hurray" } } }) do
        insist { subject["tags"].include?("success") }
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
      insist { subject }.is_a?(Array)
      insist { subject.length } == 2

      insist { subject[0]["type"] } == "original"
      insist { subject[0]["cond1"] } == "true"
      insist { subject[0]["cond2"] } == nil

      insist { subject[1]["type"] } == "clone"
      # insist { subject[1]["cond1"] } == nil
      # insist { subject[1]["cond2"] } == "true"
    end
  end
end
