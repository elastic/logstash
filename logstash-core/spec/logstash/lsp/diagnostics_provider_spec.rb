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
require "logstash/lsp/diagnostics_provider"
require "logstash/lsp/schema_provider"
require "logstash/lsp/document_manager"

describe LogStash::Lsp::DiagnosticsProvider do
  let(:schema_provider) { LogStash::Lsp::SchemaProvider.new }
  let(:document_manager) { LogStash::Lsp::DocumentManager.new }
  subject(:provider) { described_class.new(schema_provider, document_manager) }

  let(:uri) { "file:///test/pipeline.conf" }

  # Mock plugins
  let(:mock_input_plugin) do
    Class.new do
      def self.config_name
        "stdin"
      end

      def self.get_config
        {
          "codec" => { :validate => :codec, :default => "plain" },
          "type" => { :validate => :string }
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
          "patterns_dir" => { :validate => :array },
          "old_option" => { :validate => :string, :deprecated => true }
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

  describe "#diagnose" do
    context "with valid config" do
      let(:config) do
        <<~CONFIG
          input {
            stdin {
              codec => plain
            }
          }
          filter {
            grok {
              match => { "message" => "%{GREEDYDATA}" }
            }
          }
        CONFIG
      end

      before { document_manager.open(uri, config, 1) }

      it "returns empty diagnostics" do
        result = provider.diagnose(uri)

        expect(result["kind"]).to eq("full")
        expect(result["items"]).to be_empty
      end
    end

    context "with unknown plugin" do
      let(:config) do
        <<~CONFIG
          input {
            unknown_plugin {
            }
          }
        CONFIG
      end

      before { document_manager.open(uri, config, 1) }

      it "reports unknown plugin error" do
        result = provider.diagnose(uri)

        items = result["items"]
        expect(items.length).to eq(1)
        expect(items.first["severity"]).to eq(described_class::SEVERITY_ERROR)
        expect(items.first["message"]).to include("Unknown")
        expect(items.first["message"]).to include("unknown_plugin")
      end
    end

    context "with typo in plugin name" do
      let(:config) do
        <<~CONFIG
          input {
            stdn {
            }
          }
        CONFIG
      end

      before { document_manager.open(uri, config, 1) }

      it "suggests similar plugin name" do
        result = provider.diagnose(uri)

        items = result["items"]
        expect(items.length).to eq(1)
        expect(items.first["message"]).to include("Did you mean 'stdin'")
      end
    end

    context "with unknown option" do
      let(:config) do
        <<~CONFIG
          input {
            stdin {
              unknown_option => value
            }
          }
        CONFIG
      end

      before { document_manager.open(uri, config, 1) }

      it "reports unknown option warning" do
        result = provider.diagnose(uri)

        items = result["items"]
        expect(items.any? { |i| i["message"].include?("Unknown option") }).to be true
        expect(items.first["severity"]).to eq(described_class::SEVERITY_WARNING)
      end
    end

    context "with missing required option" do
      let(:config) do
        <<~CONFIG
          filter {
            grok {
              patterns_dir => []
            }
          }
        CONFIG
      end

      before { document_manager.open(uri, config, 1) }

      it "reports missing required option error" do
        result = provider.diagnose(uri)

        items = result["items"]
        expect(items.any? { |i| i["message"].include?("Missing required") }).to be true
        expect(items.any? { |i| i["message"].include?("match") }).to be true
      end
    end

    context "with deprecated option" do
      let(:config) do
        <<~CONFIG
          filter {
            grok {
              match => { "message" => "%{GREEDYDATA}" }
              old_option => test
            }
          }
        CONFIG
      end

      before { document_manager.open(uri, config, 1) }

      it "reports deprecated option warning" do
        result = provider.diagnose(uri)

        items = result["items"]
        deprecated_item = items.find { |i| i["message"].include?("deprecated") }
        expect(deprecated_item).not_to be_nil
        expect(deprecated_item["severity"]).to eq(described_class::SEVERITY_WARNING)
        expect(deprecated_item["tags"]).to include(described_class::TAG_DEPRECATED)
      end
    end

    context "with empty document" do
      before { document_manager.open(uri, "", 1) }

      it "returns empty diagnostics" do
        result = provider.diagnose(uri)
        expect(result["items"]).to be_empty
      end
    end

    context "with unopened document" do
      it "returns empty diagnostics" do
        result = provider.diagnose("file:///nonexistent.conf")
        expect(result["items"]).to be_empty
      end
    end
  end

  describe "diagnostic format" do
    let(:config) { "input {\n  unknown {}\n}" }

    before { document_manager.open(uri, config, 1) }

    it "includes range information" do
      result = provider.diagnose(uri)

      item = result["items"].first
      expect(item["range"]).to have_key("start")
      expect(item["range"]).to have_key("end")
      expect(item["range"]["start"]).to have_key("line")
      expect(item["range"]["start"]).to have_key("character")
    end

    it "includes source identifier" do
      result = provider.diagnose(uri)

      item = result["items"].first
      expect(item["source"]).to eq("logstash-lsp")
    end
  end

  describe "levenshtein distance" do
    it "calculates correct distance for similar words" do
      # Test through plugin suggestion
      document_manager.open(uri, "input { stdn {} }", 1)
      result = provider.diagnose(uri)

      # "stdn" is 1 edit away from "stdin"
      expect(result["items"].first["message"]).to include("stdin")
    end

    it "doesn't suggest for very different words" do
      document_manager.open(uri, "input { xyz {} }", 1)
      result = provider.diagnose(uri)

      # "xyz" is too different from "stdin"
      expect(result["items"].first["message"]).not_to include("Did you mean")
    end
  end
end
