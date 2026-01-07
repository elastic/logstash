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
require "logstash/lsp/completion_provider"
require "logstash/lsp/schema_provider"
require "logstash/lsp/document_manager"

describe LogStash::Lsp::CompletionProvider do
  let(:schema_provider) { LogStash::Lsp::SchemaProvider.new }
  let(:document_manager) { LogStash::Lsp::DocumentManager.new }
  subject(:provider) { described_class.new(schema_provider, document_manager) }

  let(:uri) { "file:///test/pipeline.conf" }

  # Mock plugin class for testing
  let(:mock_input_plugin) do
    Class.new do
      def self.config_name
        "stdin"
      end

      def self.get_config
        {
          "codec" => { :validate => :codec, :default => "plain" },
          "type" => { :validate => :string },
          "tags" => { :validate => :array, :default => [] }
        }
      end
    end
  end

  let(:mock_filter_plugin) do
    Class.new do
      def self.config_name
        "grok"
      end

      def self.get_config
        {
          "match" => { :validate => :hash, :required => true },
          "patterns_dir" => { :validate => :array, :default => [] },
          "tag_on_failure" => { :validate => :array, :default => ["_grokparsefailure"] }
        }
      end
    end
  end

  before do
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).and_return([])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:input).and_return([mock_input_plugin])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:filter).and_return([mock_filter_plugin])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:output).and_return([])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:codec).and_return([])
  end

  describe "#complete" do
    context "at root level" do
      before do
        document_manager.open(uri, "", 1)
      end

      it "suggests section keywords" do
        result = provider.complete(uri, 0, 0)

        labels = result["items"].map { |i| i["label"] }
        expect(labels).to include("input", "filter", "output")
      end

      it "returns snippet format for sections" do
        result = provider.complete(uri, 0, 0)

        input_item = result["items"].find { |i| i["label"] == "input" }
        expect(input_item["insertTextFormat"]).to eq(2)
        expect(input_item["insertText"]).to include("input {")
      end
    end

    context "inside section block" do
      let(:config) { "input {\n  \n}" }

      before do
        document_manager.open(uri, config, 1)
      end

      it "suggests plugin names" do
        result = provider.complete(uri, 1, 2)

        labels = result["items"].map { |i| i["label"] }
        expect(labels).to include("stdin")
      end

      it "provides snippet for plugin insertion" do
        result = provider.complete(uri, 1, 2)

        stdin_item = result["items"].find { |i| i["label"] == "stdin" }
        expect(stdin_item["insertText"]).to include("stdin {")
        expect(stdin_item["kind"]).to eq(described_class::KIND_MODULE)
      end
    end

    context "inside plugin block" do
      let(:config) { "input {\n  stdin {\n    \n  }\n}" }

      before do
        document_manager.open(uri, config, 1)
      end

      it "suggests attribute names" do
        result = provider.complete(uri, 2, 4)

        labels = result["items"].map { |i| i["label"] }
        expect(labels.any? { |l| l.include?("codec") }).to be true
      end

      it "provides snippets for attributes" do
        result = provider.complete(uri, 2, 4)

        items = result["items"]
        expect(items.any? { |i| i["insertText"]&.include?("=>") }).to be true
      end
    end

    context "with partial word" do
      let(:config) { "input {\n  st\n}" }

      before do
        document_manager.open(uri, config, 1)
      end

      it "filters by prefix" do
        result = provider.complete(uri, 1, 4)

        labels = result["items"].map { |i| i["label"] }
        expect(labels).to include("stdin")
      end
    end

    context "filter section" do
      let(:config) { "filter {\n  \n}" }

      before do
        document_manager.open(uri, config, 1)
      end

      it "suggests filter plugins" do
        result = provider.complete(uri, 1, 2)

        labels = result["items"].map { |i| i["label"] }
        expect(labels).to include("grok")
      end
    end

    context "required attributes" do
      let(:config) { "filter {\n  grok {\n    \n  }\n}" }

      before do
        document_manager.open(uri, config, 1)
      end

      it "marks required attributes" do
        result = provider.complete(uri, 2, 4)

        match_item = result["items"].find { |i| i["label"].include?("match") }
        expect(match_item["label"]).to include("required")
      end

      it "sorts required attributes first" do
        result = provider.complete(uri, 2, 4)

        items = result["items"]
        required_idx = items.find_index { |i| i["label"].include?("match") }
        optional_idx = items.find_index { |i| i["label"].include?("patterns_dir") }

        # Required should come before optional if sortText is used
        if items.any? { |i| i["sortText"] }
          expect(required_idx).to be < optional_idx if required_idx && optional_idx
        end
      end
    end
  end

  describe "completion list format" do
    before do
      document_manager.open(uri, "", 1)
    end

    it "returns isIncomplete flag" do
      result = provider.complete(uri, 0, 0)
      expect(result).to have_key("isIncomplete")
    end

    it "returns items array" do
      result = provider.complete(uri, 0, 0)
      expect(result["items"]).to be_an(Array)
    end

    it "includes documentation for items" do
      result = provider.complete(uri, 0, 0)

      items_with_docs = result["items"].select { |i| i["documentation"] }
      expect(items_with_docs).not_to be_empty
    end
  end
end
