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

require "logstash/config/source/multi_local"
require "rspec/expectations"
require "stud/temporary"
require "fileutils"
require "pathname"
require_relative "../../../support/helpers"
require_relative "../../../support/matchers"
require "spec_helper"
require "webmock/rspec"

describe LogStash::Config::Source::MultiLocal do
  subject { described_class.new(settings) }
  let(:settings) { mock_settings({}) }
  let(:pipelines_yaml_location) { "" }

  before(:each) do
    allow(subject).to receive(:pipelines_yaml_location).and_return(pipelines_yaml_location)
  end

  describe "#config_conflict?" do
    context "when `config.string` is set" do
      let(:settings) do
        mock_settings("config.string" => "input {} output {}")
      end
      it "returns false" do
        expect(subject.config_conflict?).to be_falsey
        expect(subject.conflict_messages).to be_empty
      end
    end

    context "when `config.path` is set" do
      let(:config_file) { temporary_file("") }

      let(:settings) do
        mock_settings("path.config" => config_file)
      end
      it "returns false" do
        expect(subject.config_conflict?).to be_falsey
        expect(subject.conflict_messages).to be_empty
      end
    end

    context "when `pipelines.yml` is not set" do
      let(:pipelines_yaml_location) { ::File.join(Stud::Temporary.pathname, "pipelines.yml") }
      it "returns true with messages" do
        expect(subject.config_conflict?).to be_truthy
        expect(subject.conflict_messages).to include(/Failed to read pipelines yaml file. Location:/)
      end
    end

    context "when `pipelines.yml` is only comments" do
      before(:each) do
        allow(subject).to receive(:read_pipelines_from_yaml).and_return(::YAML.load("# blah\n# blah\n# blah\n", fallback: false))
      end
      it "returns true with messages" do
        expect(subject.config_conflict?).to be_truthy
        expect(subject.conflict_messages).to include(/Pipelines YAML file is empty. Location:/)
      end
    end
  end

  describe "#match?" do
    context "when `config.string` is set" do
      let(:settings) do
        mock_settings("config.string" => "input {} output {}")
      end
      it "returns false" do
        expect(subject.match?).to be_falsey
      end
    end

    context "when `config.path` are set`" do
      let(:config_file) { temporary_file("input {} output {}") }

      let(:settings) do
        mock_settings("path.config" => config_file)
      end

      it "returns false" do
        expect(subject.match?).to be_falsey
      end
    end

    context "when both `config.string` and `path.config` are set" do
      let(:settings) do
        mock_settings("config.string" => "input {} output {}", "path.config" => temporary_file("input {} output {}"))
      end
      it "returns false" do
        expect(subject.match?).to be_falsey
      end
    end

    context "when neither `config.path` nor `path.config` are set` and pipelines.yml has configs" do
      before do
        allow(subject).to receive(:invalid_pipelines_detected?).and_return(false)
      end
      it "returns true" do
        expect(subject.match?).to be_truthy
      end
    end
  end

  describe "#detect_duplicate_pipelines" do
    let(:retrieved_pipelines) { [{}] }
    let(:retrieved_pipelines_configs) { retrieved_pipelines.map {|h| mock_settings(h) } }
    context "when there are duplicate pipeline ids" do
      let(:retrieved_pipelines) do
        [
          {"pipeline.id" => "main", "config.string" => "input {} output {}"},
          {"pipeline.id" => "main", "config.string" => "input {} output {}"},
        ]
      end
      it "should raise a ConfigurationError" do
        expect { subject.detect_duplicate_pipelines(retrieved_pipelines_configs) }.to raise_error(::LogStash::ConfigurationError)
      end
    end
    context "when there are no duplicate pipeline ids" do
      let(:retrieved_pipelines) do
        [
          {"pipeline.id" => "main", "config.string" => "input {} output {}"},
          {"pipeline.id" => "backup", "config.string" => "input {} output {}"},
        ]
      end
      it "should not raise an error" do
        expect { subject.detect_duplicate_pipelines(retrieved_pipelines_configs) }.to_not raise_error
      end
    end
  end

  describe "#pipeline_configs" do
    let(:retrieved_pipelines) do
      [
        { "pipeline.id" => "main", "config.string" => "input {} output {}" },
        { "pipeline.id" => "backup", "config.string" => "input {} output {}" }
      ]
    end
    before(:each) do
      allow(subject).to receive(:retrieve_yaml_pipelines).and_return(retrieved_pipelines)
    end

    it "should return instances of PipelineConfig" do
      configs = subject.pipeline_configs
      expect(configs).to be_a(Array)
      expect(subject.pipeline_configs.first).to be_a(::LogStash::Config::PipelineConfig)
      expect(subject.pipeline_configs.last).to be_a(::LogStash::Config::PipelineConfig)
    end

    context "using non pipeline related settings" do
      let(:retrieved_pipelines) do [
          { "pipeline.id" => "main", "config.string" => "", "api.http.port" => 22222 },
        ]
      end
      it "should raise and error" do
        expect { subject.pipeline_configs }.to raise_error(ArgumentError)
      end
    end

    context 'using dead letter queue settings' do
      let(:retrieved_pipelines) do [
          { "pipeline.id" => "main", "path.dead_letter_queue" => "/tmp", "dead_letter_queue.max_bytes" => 10000 },
      ]
      end
      it "should not raise an error" do
        expect { subject.pipeline_configs }.not_to raise_error(ArgumentError)
      end
    end

    context 'using dead letter queue settings with storage and retention policies' do
      let(:retrieved_pipelines) do [
          { "pipeline.id" => "main", "path.dead_letter_queue" => "/tmp", "dead_letter_queue.max_bytes" => 10000,
            "dead_letter_queue.storage_policy" => "drop_newer", "dead_letter_queue.retain.age" => "5d" },
      ]
      end
      it "should not raise an error" do
        expect { subject.pipeline_configs }.not_to raise_error(ArgumentError)
      end
    end
  end
end
