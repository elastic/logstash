require "test_utils"
require "logstash/filters/noop"

#NOOP filter is perfect for testing Filters::Base features with minimal overhead
describe LogStash::Filters::NOOP do
  extend LogStash::RSpec

  describe "adding multiple value to one field" do
    config <<-CONFIG
    filter {
      noop {
        add_field => ["new_field", "new_value"]
        add_field => ["new_field", "new_value_2"]
      }
    }
    CONFIG

    sample "example" do
      insist { subject["new_field"] } == ["new_value", "new_value_2"]
    end
  end

  describe "remove_tag" do
    config <<-CONFIG
    filter {
      if [type] == "noop" and "t1" in [tags] {
        noop {
          remove_tag => ["t2", "t3"]
        }
      }
    }
    CONFIG

    sample("type" => "noop", "tags" => ["t4"]) do
      insist { subject["tags"] } == ["t4"]
    end

    sample("type" => "noop", "tags" => ["t1", "t2", "t3"]) do
      insist { subject["tags"] } == ["t1"]
    end

    sample("type" => "noop", "tags" => ["t1", "t2"]) do
      insist { subject["tags"] } == ["t1"]
    end
  end

  describe "remove_tag with dynamic value" do
    config <<-CONFIG
    filter {
      if [type] == "noop" and "t1" in [tags] {
        noop {
          remove_tag => ["%{blackhole}"]
        }
      }
    }
    CONFIG

    sample("type" => "noop", "tags" => ["t1", "goaway", "t3"], "blackhole" => "goaway") do
      insist { subject["tags"] } == ["t1", "t3"]
    end
  end

  describe "remove_field" do
    config <<-CONFIG
    filter {
      if [type] == "noop" {
        noop {
          remove_field => ["t2", "t3"]
        }
      }
    }
    CONFIG

    sample("type" => "noop", "t4" => "four") do
      insist { subject }.include?("t4")
    end

    sample("type" => "noop", "t1" => "one", "t2" => "two", "t3" => "three") do
      insist { subject }.include?("t1")
      reject { subject }.include?("t2")
      reject { subject }.include?("t3")
    end

    sample("type" => "noop", "t1" => "one", "t2" => "two") do
      insist { subject }.include?("t1")
      reject { subject }.include?("t2")
    end
  end

  describe "remove_field with dynamic value in field name" do
    config <<-CONFIG
    filter {
      if [type] == "noop" {
        noop {
          remove_field => ["%{blackhole}"]
        }
      }
    }
    CONFIG

    sample("type" => "noop", "blackhole" => "go", "go" => "away") do
      insist { subject }.include?("blackhole")
      reject { subject }.include?("go")
    end
  end
end
