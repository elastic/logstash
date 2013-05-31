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

    sample("type" => "noop") do
      insist { subject["tags"] } == ["test"]
    end

    sample("type" => "not_noop") do
      insist { subject["tags"] }.nil?
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

    sample("type" => "noop") do
      insist { subject["tags"] }.nil?
    end

    sample("type" => "noop", "tags" => ["t1", "t2"]) do
      insist { subject["tags"] } == ["t1", "t2", "test"]
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

    sample("type" => "noop") do
      insist { subject["tags"] }.nil?
    end

    sample("type" => "noop", "tags" => ["t1"]) do
      insist { subject["tags"] } == ["t1"]
    end

    sample("type" => "noop", "tags" => ["t1", "t2"]) do
      insist { subject["tags"] } == ["t1", "t2", "test"]
    end

    sample("type" => "noop", "tags" => ["t1", "t2", "t3"]) do
      insist { subject["tags"] } == ["t1", "t2", "t3", "test"]
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

    sample("type" => "noop") do
      insist { subject["tags"] }.nil?
    end

    sample("type" => "noop", "tags" => ["t1"]) do
      insist { subject["tags"] } == ["t1", "test"]
    end

    sample("type" => "noop", "tags" => ["t1", "t2"]) do
      insist { subject["tags"] } == ["t1", "t2"]
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

    sample("type" => "noop", "tags" => ["t1", "t2", "t4"]) do
      insist { subject["tags"] } == ["t1", "t2", "t4"]
    end

    sample("type" => "noop", "tags" => ["t1", "t3", "t4"]) do
      insist { subject["tags"] } == ["t1", "t3", "t4"]
    end

    sample("type" => "noop", "tags" => ["t1", "t4", "t5"]) do
      insist { subject["tags"] } == ["t1", "t4", "t5", "test"]
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
      noop {
        type => "noop"
        tags => ["t1"]
        remove_tag => ["%{blackhole}"]
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
      noop {
        type => "noop"
        remove_field => ["t2", "t3"]
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
      noop {
        type => "noop"
        remove_field => ["%{blackhole}"]
      }
    }
    CONFIG

    sample("type" => "noop", "blackhole" => "go", "go" => "away") do
      insist { subject }.include?("blackhole")
      reject { subject }.include?("go")
    end
  end

  describe "checking AND include_any logic on tags filter" do
    config <<-CONFIG
    filter {
      noop {
        tags        => ["two", "three", "four"]
        include_any => false
        add_tag     => ["match"]
      }
    }
    CONFIG

    sample("tags" => ["one", "two", "three", "four", "five"]) do
      insist { subject["tags"] }.include?("match")
    end

    sample("tags" => ["one", "two", "four", "five"]) do
      reject { subject["tags"] }.include?("match")
    end

    sample({}) do
      insist { subject["tags"] }.nil?
    end
  end

  describe "checking OR include_any logic on tags filter" do
    config <<-CONFIG
    filter {
      noop {
        tags        => ["two", "three", "four"]
        include_any => true
        add_tag     => ["match"]
      }
    }
    CONFIG

    sample("tags" => ["one1", "two2", "three", "four4", "five5"]) do
      insist { subject["tags"] }.include?("match")
    end

    sample("tags" => ["one1", "two2", "three3", "four4", "five5"]) do
      reject { subject["tags"] }.include?("match")
    end

    sample({}) do
      insist { subject["tags"] }.nil?
    end
  end

  describe "checking AND include_any logic on include_fields filter" do
    config <<-CONFIG
    filter {
      noop {
        include_fields => ["two", "two", "three", "three", "four", "four"]
        include_any    => false
        add_tag        => ["match"]
      }
    }
    CONFIG

    sample("one" => "1", "two" => "2", "three" => "3", "four" => "4", "five" => "5") do
      insist { subject["tags"] }.include?("match")
    end

    sample("one" => "1", "two" => "2", "four" => "4", "five" => "5") do
      insist { subject["tags"] }.nil?
    end

    sample({}) do
      insist { subject["tags"] }.nil?
    end
  end

  describe "checking OR include_any logic on include_fields filter" do
    config <<-CONFIG
    filter {
      noop {
        include_fields => ["two", "two", "three", "three", "four", "four"]
        include_any    => true
        add_tag        => ["match"]
      }
    }
    CONFIG

    sample("one1" => "1", "two2" => "2", "three" => "3", "four4" => "4", "five5" => "5") do
      insist { subject["tags"] }.include?("match")
    end

    sample("one1" => "1", "two2" => "2", "three3" => "3", "four4" => "4", "five5" => "5") do
      insist { subject["tags"] }.nil?
    end

    sample({}) do
      insist { subject["tags"] }.nil?
    end
  end

  describe "checking AND exclude_any logic on exclude_tags filter" do
    config <<-CONFIG
    filter {
      noop {
        exclude_tags => ["two", "three", "four"]
        exclude_any  => false
        add_tag      => ["match"]
      }
    }
    CONFIG

    sample("tags" => ["one", "two", "three", "four", "five"]) do
      reject { subject["tags"] }.include?("match")
    end

    sample("tags" => ["one", "two", "four", "five"]) do
      insist { subject["tags"] }.include?("match")
    end

    sample({}) do
      insist { subject["tags"] }.include?("match")
    end
  end

  describe "checking OR exclude_any logic on exclude_tags filter" do
    config <<-CONFIG
    filter {
      noop {
        exclude_tags => ["two", "three", "four"]
        exclude_any  => true
        add_tag      => ["match"]
      }
    }
    CONFIG

    sample("tags" => ["one", "two", "three", "four", "five"]) do
      reject { subject["tags"] }.include?("match")
    end

    sample("tags" => ["one1", "two2", "three", "four4", "five5"]) do
      reject { subject["tags"] }.include?("match")
    end

    sample("tags" => ["one1", "two2", "three3", "four4", "five5"]) do
      insist { subject["tags"] }.include?("match")
    end

    sample({}) do
      insist { subject["tags"] }.include?("match")
    end
  end

  describe "checking AND exclude_any logic on exclude_fields filter" do
    config <<-CONFIG
    filter {
      noop {
        exclude_fields => ["two", "two", "three", "three", "four", "four"]
        exclude_any    => false
        add_tag        => ["match"]
      }
    }
    CONFIG

    sample("one" => "1", "two" => "2", "three" => "3", "four" => "4", "five" => "5") do
      insist { subject["tags"] }.nil?
    end

    sample("one" => "1", "two" => "2", "four" => "4", "five" => "5") do
      insist { subject["tags"] }.include?("match")
    end

    sample({}) do
      insist { subject["tags"] }.include?("match")
    end
  end

  describe "checking OR exclude_any logic on exclude_fields filter" do
    config <<-CONFIG
    filter {
      noop {
        exclude_fields => ["two", "two", "three", "three", "four", "four"]
        exclude_any    => true
        add_tag        => ["match"]
      }
    }
    CONFIG

    sample("one1" => "1", "two2" => "2", "three" => "3", "four4" => "4", "five5" => "5") do
      insist { subject["tags"] }.nil?
    end

    sample("one1" => "1", "two2" => "2", "three3" => "3", "four4" => "4", "five5" => "5") do
      insist { subject["tags"] }.include?("match")
    end

    sample({}) do
      insist { subject["tags"] }.include?("match")
    end
  end
end
