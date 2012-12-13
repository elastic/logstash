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

  describe "type parsing" do
    config <<-CONFIG
    filter {
      noop {
        type => "noop"
        add_tag => ["test"]
      }
    }
    CONFIG

    sample({"@type" => "noop"})  do
      insist { subject.tags } == ["test"]
    end

    sample({"@type" => "not_noop"})  do
      insist { subject.tags } == []
    end
  end

  describe "tags parsing with one tag" do
    config <<-CONFIG
    filter {
      noop {
        type => "noop"
        tags => ["t1"]
        add_tag => ["test"]
      }
    }
    CONFIG

    sample({"@type" => "noop"})  do
      insist { subject.tags} == []
    end

    sample({"@type" => "noop", "@tags" => ["t1", "t2"]})  do
      insist { subject.tags} == ["t1", "t2", "test"]
    end
  end

  describe "tags parsing with multiple tags" do
    config <<-CONFIG
    filter {
      noop {
        type => "noop"
        tags => ["t1", "t2"]
        add_tag => ["test"]
      }
    }
    CONFIG

    sample({"@type" => "noop"})  do
      insist { subject.tags} == []
    end

    sample({"@type" => "noop", "@tags" => ["t1"]})  do
      insist { subject.tags} == ["t1"]
    end

    sample({"@type" => "noop", "@tags" => ["t1", "t2"]})  do
      insist { subject.tags} == ["t1", "t2", "test"]
    end

    sample({"@type" => "noop", "@tags" => ["t1", "t2", "t3"]})  do
      insist { subject.tags} == ["t1", "t2", "t3", "test"]
    end
  end

  describe "exclude_tags with 1 tag" do
    config <<-CONFIG
    filter {
      noop {
        type => "noop"
        tags => ["t1"]
        add_tag => ["test"]
        exclude_tags => ["t2"]
      }
    }
    CONFIG

    sample({"@type" => "noop"})  do
      insist { subject.tags} == []
    end

    sample({"@type" => "noop", "@tags" => ["t1"]})  do
      insist { subject.tags} == ["t1", "test"]
    end

    sample({"@type" => "noop", "@tags" => ["t1", "t2"]})  do
      insist { subject.tags} == ["t1", "t2"]
    end
  end

  describe "exclude_tags with >1 tags" do
    config <<-CONFIG
    filter {
      noop {
        type => "noop"
        tags => ["t1"]
        add_tag => ["test"]
        exclude_tags => ["t2", "t3"]
      }
    }
    CONFIG

    sample({"@type" => "noop", "@tags" => ["t1", "t2", "t4"]})  do
      insist { subject.tags} == ["t1", "t2", "t4"]
    end

    sample({"@type" => "noop", "@tags" => ["t1", "t3", "t4"]})  do
      insist { subject.tags} == ["t1", "t3", "t4"]
    end

    sample({"@type" => "noop", "@tags" => ["t1", "t4", "t5"]})  do
      insist { subject.tags} == ["t1", "t4", "t5", "test"]
    end
  end

  describe "remove_tag" do
    config <<-CONFIG
    filter {
      noop {
        type => "noop"
        tags => ["t1"]
        remove_tag => ["t2", "t3"]
      }
    }
    CONFIG

    sample({"@type" => "noop", "@tags" => ["t4"]})  do
      insist { subject.tags} == ["t4"]
    end

    sample({"@type" => "noop", "@tags" => ["t1", "t2", "t3"]})  do
      insist { subject.tags} == ["t1"]
    end

    sample({"@type" => "noop", "@tags" => ["t1", "t2"]})  do
      insist { subject.tags} == ["t1"]
    end
  end
end
