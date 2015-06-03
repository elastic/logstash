# encoding: utf-8
require "spec_helper"
require "logstash/json"

# use a dummy NOOP filter to test Filters::Base
class LogStash::Filters::NOOP < LogStash::Filters::Base
  config_name "noop"
  milestone 2

  def register; end

  def filter(event)
    return unless filter?(event)
    filter_matched(event)
  end
end

describe LogStash::Filters::Base do
  subject {LogStash::Filters::Base.new({})}

  it "should provide method interfaces to override" do
    expect{subject.register}.to raise_error(RuntimeError)
    expect{subject.filter(:foo)}.to raise_error(RuntimeError)
  end

  it "should provide class public API" do
    [:register, :filter, :multi_filter, :execute, :threadsafe?, :filter_matched, :filter?, :teardown].each do |method|
      expect(subject).to respond_to(method)
    end
  end

  context "multi_filter" do
    let(:event1){LogStash::Event.new}
    let(:event2){LogStash::Event.new}

    it "should multi_filter without new events" do
      allow(subject).to receive(:filter) do |event, &block|
        nil
      end
      expect(subject.multi_filter([event1])).to eq([event1])
    end

    it "should multi_filter with new events" do
      allow(subject).to receive(:filter) do |event, &block|
        block.call(event2)
      end
      expect(subject.multi_filter([event1])).to eq([event1, event2])
    end
  end
end

describe LogStash::Filters::NOOP do

  describe "adding multiple values to one field" do
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

    # also test from Json deserialized data to test the handling of native Java collections by JrJackson
    # see https://github.com/elastic/logstash/issues/2261
    sample(LogStash::Json.load("{\"type\":\"noop\", \"tags\":[\"t1\", \"t2\", \"t3\"]}")) do
      insist { subject["tags"] } == ["t1"]
    end

    sample("type" => "noop", "tags" => ["t1", "t2"]) do
      insist { subject["tags"] } == ["t1"]
    end

    # also test from Json deserialized data to test the handling of native Java collections by JrJackson
    # see https://github.com/elastic/logstash/issues/2261
    sample(LogStash::Json.load("{\"type\":\"noop\", \"tags\":[\"t1\", \"t2\"]}")) do
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

    # also test from Json deserialized data to test the handling of native Java collections by JrJackson
    # see https://github.com/elastic/logstash/issues/2261
    sample(LogStash::Json.load("{\"type\":\"noop\", \"tags\":[\"t1\", \"goaway\", \"t3\"], \"blackhole\":\"goaway\"}")) do
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

 describe "remove_field on deep objects" do
    config <<-CONFIG
    filter {
      noop {
        type => "noop"
        remove_field => ["[t1][t2]"]
      }
    }
    CONFIG

    sample("type" => "noop", "t1" => {"t2" => "two", "t3" => "three"}) do
      insist { subject }.include?("t1")
      reject { subject }.include?("[t1][t2]")
      insist { subject }.include?("[t1][t3]")
    end
  end

 describe "remove_field on array" do
    config <<-CONFIG
    filter {
      noop {
        type => "noop"
        remove_field => ["[t1][0]"]
      }
    }
    CONFIG

    sample("type" => "noop", "t1" => ["t2", "t3"]) do
      insist { subject }.include?("t1")
      insist { subject["[t1][0]"] } == "t3"
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
end
