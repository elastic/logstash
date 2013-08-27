require "test_utils"

module ConditionalFancines
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

describe "conditionals" do
  extend LogStash::RSpec
  extend ConditionalFancines

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
        if ![foo] != "bar" {
          mutate { add_field => { "not" => "works" } }
        }
        if !([foo] != "bar") {
          mutate { add_field => { "not2" => "works too" } }
        }
      }
    CONFIG

    sample({"foo" => "bar"}) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] } == "world"
      insist { subject["fancy"] }.nil?
      insist { subject["free"] }.nil?
      insist { subject["not"] } == "works"
      insist { subject["not2"] } == "works too"
    end

    sample({"notfoo" => "bar"}) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] }.nil?
      insist { subject["free"] } == "hugs"
      insist { subject["not"] }.nil?
      insist { subject["not2"] }.nil?
    end

    sample({"bar" => "baz"}) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] } == "pants"
      insist { subject["free"] }.nil?
      insist { subject["not"] }.nil?
      insist { subject["not2"] }.nil?
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
        if !("oink" in [greeting]) {
          mutate { add_tag => "string not in field" }
        }
        if [foo] in ["hello", "world", "foo"] {
          mutate { add_tag => "field in list" }
        }
        if [missing] in [alsomissing] {
          mutate { add_tag => "shouldnotexist" }
        }
      }
    CONFIG

    sample("foo" => "foo", "foobar" => "foobar", "greeting" => "hello world") do
      insist { subject["tags"] }.include?("field in field")
      insist { subject["tags"] }.include?("field in string")
      insist { subject["tags"] }.include?("string in field")
      insist { subject["tags"] }.include?("string not in field")
      insist { subject["tags"] }.include?("field in list")
      reject { subject["tags"] }.include?("shouldnotexist")
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
end
