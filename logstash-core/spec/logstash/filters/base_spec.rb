# encoding: utf-8
require "spec_helper"
require "logstash/json"
require 'support/pipeline/pipeline_helpers'

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
    [:register, :filter, :multi_filter, :execute, :threadsafe?, :close].each do |method|
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
  extend PipelineHelpers

  describe "adding multiple values to one field" do
    config <<-CONFIG
    filter {
      noop {
        add_field => ["new_field", "new_value"]
        add_field => ["new_field", "new_value_2"]
      }
    }
    CONFIG

    sample_one("example") do
      insist { subject.get("new_field") } == ["new_value", "new_value_2"]
    end
  end

  describe "type parsing" do
    config <<-CONFIG
    filter {
      noop {
        add_tag => ["test"]
      }
    }
    CONFIG

    sample_one("type" => "noop") do
      insist { subject.get("tags") } == ["test"]
    end
  end

  describe "tags parsing with one tag" do
    config <<-CONFIG
    filter {
      noop {
        add_tag => ["test"]
      }
    }
    CONFIG

    sample_one("type" => "noop") do
      insist { subject.get("tags") } == ["test"]
    end

    sample_one("type" => "noop", "tags" => ["t1", "t2"]) do
      insist { subject.get("tags") } == ["t1", "t2", "test"]
    end
  end

  describe "tags parsing with one tag as string value" do
    config <<-CONFIG
    filter {
      noop {
        add_tag => ["bar"]
      }
    }
    CONFIG

    sample_one("type" => "noop") do
      insist { subject.get("tags") } == ["bar"]
    end

    sample_one("type" => "noop", "tags" => "foo") do
      insist { subject.get("tags") } == ["foo", "bar"]
    end
  end

  describe "tags parsing with duplicate tags" do
    config <<-CONFIG
    filter {
      noop {
        add_tag => ["foo"]
      }
    }
    CONFIG

    sample_one("type" => "noop", "tags" => "foo") do
      # this is completely weird but seems to be already expected in other specs
      insist { subject.get("tags") } == ["foo", "foo"]
    end
  end

  describe "tags parsing with multiple tags" do
    config <<-CONFIG
    filter {
      noop {
        add_tag => ["test"]
      }
    }
    CONFIG

    sample_one("type" => "noop") do
      insist { subject.get("tags") } == ["test"]
    end

    sample_one("type" => "noop", "tags" => ["t1"]) do
      insist { subject.get("tags") } == ["t1", "test"]
    end

    sample_one("type" => "noop", "tags" => ["t1", "t2"]) do
      insist { subject.get("tags") } == ["t1", "t2", "test"]
    end

    sample_one("type" => "noop", "tags" => ["t1", "t2", "t3"]) do
      insist { subject.get("tags") } == ["t1", "t2", "t3", "test"]
    end
  end

  describe "remove_tag" do
    config <<-CONFIG
    filter {
      noop {
        remove_tag => ["t2", "t3"]
      }
    }
    CONFIG

    sample_one("type" => "noop", "tags" => "foo") do
      insist { subject.get("tags") } == ["foo"]
    end

    sample_one("type" => "noop", "tags" => "t2") do
      insist { subject.get("tags") } == []
    end

    sample_one("type" => "noop", "tags" => ["t2"]) do
      insist { subject.get("tags") } == []
    end

    sample_one("type" => "noop", "tags" => ["t4"]) do
      insist { subject.get("tags") } == ["t4"]
    end

    sample_one("type" => "noop", "tags" => ["t1", "t2", "t3"]) do
      insist { subject.get("tags") } == ["t1"]
    end

    # also test from Json deserialized data to test the handling of native Java collections by JrJackson
    # see https://github.com/elastic/logstash/issues/2261
    sample_one(LogStash::Json.load("{\"type\":\"noop\", \"tags\":[\"t1\", \"t2\", \"t3\"]}")) do
      insist { subject.get("tags") } == ["t1"]
    end

    sample_one("type" => "noop", "tags" => ["t1", "t2"]) do
      insist { subject.get("tags") } == ["t1"]
    end

    # also test from Json deserialized data to test the handling of native Java collections by JrJackson
    # see https://github.com/elastic/logstash/issues/2261
    sample_one(LogStash::Json.load("{\"type\":\"noop\", \"tags\":[\"t1\", \"t2\"]}")) do
      insist { subject.get("tags") } == ["t1"]
    end
  end

  describe "remove_tag with dynamic value" do
    config <<-CONFIG
    filter {
      noop {
        remove_tag => ["%{blackhole}"]
      }
    }
    CONFIG

    sample_one("type" => "noop", "tags" => ["t1", "goaway", "t3"], "blackhole" => "goaway") do
      insist { subject.get("tags") } == ["t1", "t3"]
    end

    # also test from Json deserialized data to test the handling of native Java collections by JrJackson
    # see https://github.com/elastic/logstash/issues/2261
    sample_one(LogStash::Json.load("{\"type\":\"noop\", \"tags\":[\"t1\", \"goaway\", \"t3\"], \"blackhole\":\"goaway\"}")) do
      insist { subject.get("tags") } == ["t1", "t3"]
    end
  end

  describe "remove_field" do
    config <<-CONFIG
    filter {
      noop {
        remove_field => ["t2", "t3"]
      }
    }
    CONFIG

    sample_one("type" => "noop", "t4" => "four") do
      insist { subject }.include?("t4")
    end

    sample_one("type" => "noop", "t1" => "one", "t2" => "two", "t3" => "three") do
      insist { subject }.include?("t1")
      reject { subject }.include?("t2")
      reject { subject }.include?("t3")
    end

    sample_one("type" => "noop", "t1" => "one", "t2" => "two") do
      insist { subject }.include?("t1")
      reject { subject }.include?("t2")
    end
  end

  describe "remove_field on tags" do
    config <<-CONFIG
    filter {
      noop {
        remove_field => ["tags"]
      }
    }
    CONFIG

    sample_one("tags" => "foo") do
      reject { subject }.include?("tags")
    end
  end

  describe "remove_field on deep objects" do
    config <<-CONFIG
    filter {
      noop {
        remove_field => ["[t1][t2]"]
      }
    }
    CONFIG

    sample_one("type" => "noop", "t1" => {"t2" => "two", "t3" => "three"}) do
      insist { subject }.include?("t1")
      reject { subject }.include?("[t1][t2]")
      insist { subject }.include?("[t1][t3]")
    end
  end

 describe "remove_field on array" do
    config <<-CONFIG
    filter {
      noop {
        remove_field => ["[t1][0]"]
      }
    }
    CONFIG

    sample_one("type" => "noop", "t1" => ["t2", "t3"]) do
      insist { subject }.include?("t1")
      insist { subject.get("[t1][0]") } == "t3"
    end
  end

  describe "remove_field with dynamic value in field name" do
    config <<-CONFIG
    filter {
      noop {
        remove_field => ["%{blackhole}"]
      }
    }
    CONFIG

    sample_one("type" => "noop", "blackhole" => "go", "go" => "away") do
      insist { subject }.include?("blackhole")
      reject { subject }.include?("go")
    end
  end

  describe "when neither add_tag nor remove_tag is specified, the tags field is left untouched" do
    config <<-CONFIG
    filter {
      noop {}
    }
    CONFIG

    sample_one("type" => "noop", "go" => "away", "tags" => {"blackhole" => "go"}) do
      expect(subject.get("[tags][blackhole]")).to eq("go")
    end

  end
end
