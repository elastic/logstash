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
    expect {subject.register}.to raise_error(RuntimeError)
    expect {subject.filter(:foo)}.to raise_error(RuntimeError)
  end

  it "should provide class public API" do
    [:register, :filter, :multi_filter, :execute, :threadsafe?, :close].each do |method|
      expect(subject).to respond_to(method)
    end
  end

  context "multi_filter" do
    let(:event1) {LogStash::Event.new}
    let(:event2) {LogStash::Event.new}

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
  let(:settings) do
    # settings is used by sample_one.
    # This was originally set directly in sample_one and
    # pipeline.workers was also set to 1. I am preserving
    # this setting here for the sake of minimizing change
    # but unsure if this is actually required.

    s = LogStash::SETTINGS.clone
    s.set_value("pipeline.workers", 1)
    s
  end

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
      expect(subject.get("new_field")).to eq(["new_value", "new_value_2"])
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
      expect(subject.get("tags")).to eq(["test"])
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
      expect(subject.get("tags")).to eq(["test"])
    end

    sample_one("type" => "noop", "tags" => ["t1", "t2"]) do
      expect(subject.get("tags")).to eq(["t1", "t2", "test"])
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
      expect(subject.get("tags")).to eq(["bar"])
    end

    sample_one("type" => "noop", "tags" => "foo") do
      expect(subject.get("tags")).to eq(["foo", "bar"])
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
      expect(subject.get("tags")).to eq(["foo", "foo"])
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
      expect(subject.get("tags")).to eq(["test"])
    end

    sample_one("type" => "noop", "tags" => ["t1"]) do
      expect(subject.get("tags")).to eq(["t1", "test"])
    end

    sample_one("type" => "noop", "tags" => ["t1", "t2"]) do
      expect(subject.get("tags")).to eq(["t1", "t2", "test"])
    end

    sample_one("type" => "noop", "tags" => ["t1", "t2", "t3"]) do
      expect(subject.get("tags")).to eq(["t1", "t2", "t3", "test"])
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
      expect(subject.get("tags")).to eq(["foo"])
    end

    sample_one("type" => "noop", "tags" => "t2") do
      expect(subject.get("tags")).to be_empty
    end

    sample_one("type" => "noop", "tags" => ["t2"]) do
      expect(subject.get("tags")).to be_empty
    end

    sample_one("type" => "noop", "tags" => ["t4"]) do
      expect(subject.get("tags")).to eq(["t4"])
    end

    sample_one("type" => "noop", "tags" => ["t1", "t2", "t3"]) do
      expect(subject.get("tags")).to eq(["t1"])
    end

    # also test from Json deserialized data to test the handling of native Java collections by JrJackson
    # see https://github.com/elastic/logstash/issues/2261
    sample_one(LogStash::Json.load("{\"type\":\"noop\", \"tags\":[\"t1\", \"t2\", \"t3\"]}")) do
      expect(subject.get("tags")).to eq(["t1"])
    end

    sample_one("type" => "noop", "tags" => ["t1", "t2"]) do
      expect(subject.get("tags")).to eq(["t1"])
    end

    # also test from Json deserialized data to test the handling of native Java collections by JrJackson
    # see https://github.com/elastic/logstash/issues/2261
    sample_one(LogStash::Json.load("{\"type\":\"noop\", \"tags\":[\"t1\", \"t2\"]}")) do
      expect(subject.get("tags")).to eq(["t1"])
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
      expect(subject.get("tags")).to eq(["t1", "t3"])
    end

    # also test from Json deserialized data to test the handling of native Java collections by JrJackson
    # see https://github.com/elastic/logstash/issues/2261
    sample_one(LogStash::Json.load("{\"type\":\"noop\", \"tags\":[\"t1\", \"goaway\", \"t3\"], \"blackhole\":\"goaway\"}")) do
      expect(subject.get("tags")).to eq(["t1", "t3"])
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
      expect(subject).to include("t4")
    end

    sample_one("type" => "noop", "t1" => "one", "t2" => "two", "t3" => "three") do
      expect(subject).to include("t1")
      expect(subject).to_not include("t2")
      expect(subject).to_not include("t3")
    end

    sample_one("type" => "noop", "t1" => "one", "t2" => "two") do
      expect(subject).to include("t1")
      expect(subject).to_not include("t2")
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
      expect(subject).to_not include("tags")
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
      expect(subject).to include("t1")
      expect(subject).to_not include("[t1][t2]")
      expect(subject).to include("[t1][t3]")
    end
  end

  describe "remove_field within @metadata" do
    config <<-CONFIG
    filter {
      noop {
        remove_field => ["[@metadata][f1]", "[@metadata][f2]", "[@metadata][f4][f5]"]
      }
    }
    CONFIG

    sample_one("type" => "noop", "@metadata" => {"f1" => "one", "f2" => { "f3" => "three"}, "f4" => { "f5" => "five", "f6" => "six"}, "f7" => "seven"}) do
      expect(subject).to_not include("[@metadata][f1]")
      expect(subject).to_not include("[@metadata][f2]")
      expect(subject).to include("[@metadata][f4]")
      expect(subject).to_not include("[@metadata][f4][f5]")
      expect(subject).to include("[@metadata][f4][f6]")
      expect(subject).to include("[@metadata][f7]")
    end
  end

  describe "remove_field on @metadata" do
    config <<-CONFIG
    filter {
      noop {
        remove_field => ["[@metadata]"]
      }
    }
    CONFIG

    sample_one("type" => "noop", "@metadata" => {"f1" => "one", "f2" => { "f3" => "three"}}) do
      expect(subject).to include("[@metadata]")
      expect(subject).to_not include("[@metadata][f1]")
      expect(subject).to_not include("[@metadata][f2]")
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
      expect(subject).to include("t1")
      expect(subject.get("[t1][0]")).to eq("t3")
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
      expect(subject).to include("blackhole")
      expect(subject).to_not include("go")
    end
  end

  describe "when neither add_tag nor remove_tag is specified, the tags field is left untouched" do
    config <<-CONFIG
    filter {
      noop {}
    }
    CONFIG

    sample_one("type" => "noop", "go" => "away", "tags" => "blackhole") do
      expect(subject.get("[tags]")).to eq("blackhole")
    end
  end

  describe "when metrics are disabled" do
    describe "An error should not be raised, and the event should be processed" do
      config <<-CONFIG
        filter {
          noop { enable_metric => false }
        }
      CONFIG

      sample_one("type" => "noop", "tags" => "blackhole") do
        expect(subject.get("[tags]")).to eq("blackhole")
      end
    end
  end
end
