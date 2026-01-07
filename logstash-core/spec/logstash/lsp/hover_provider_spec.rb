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
require "logstash/lsp/hover_provider"
require "logstash/lsp/schema_provider"
require "logstash/lsp/document_manager"

describe LogStash::Lsp::HoverProvider do
  let(:schema_provider) { LogStash::Lsp::SchemaProvider.new }
  let(:document_manager) { LogStash::Lsp::DocumentManager.new }
  subject(:provider) { described_class.new(schema_provider, document_manager) }

  let(:uri) { "file:///test/pipeline.conf" }

  # Mock plugin class
  let(:mock_input_plugin) do
    Class.new do
      def self.config_name
        "stdin"
      end

      def self.get_config
        {
          "codec" => { :validate => :codec, :default => "plain", :description => "The codec for input data" },
          "type" => { :validate => :string, :description => "Add a type field to all events" },
          "tags" => { :validate => :array, :default => [], :description => "Add tags to events" }
        }
      end
    end
  end

  before do
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).and_return([])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:input).and_return([mock_input_plugin])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:filter).and_return([])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:output).and_return([])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:codec).and_return([])
  end

  describe "#hover" do
    context "on section keyword" do
      let(:config) { "input {\n}\n" }

      before { document_manager.open(uri, config, 1) }

      it "returns section documentation" do
        result = provider.hover(uri, 0, 2)

        expect(result).not_to be_nil
        expect(result["contents"]["kind"]).to eq("markdown")
        expect(result["contents"]["value"]).to include("Input Section")
      end

      it "includes range information" do
        result = provider.hover(uri, 0, 2)

        expect(result["range"]["start"]["line"]).to eq(0)
        expect(result["range"]["start"]["character"]).to eq(0)
        expect(result["range"]["end"]["character"]).to eq(5)
      end
    end

    context "on plugin name" do
      let(:config) { "input {\n  stdin {\n  }\n}" }

      before { document_manager.open(uri, config, 1) }

      it "returns plugin documentation" do
        result = provider.hover(uri, 1, 4)

        expect(result).not_to be_nil
        expect(result["contents"]["value"]).to include("stdin")
        expect(result["contents"]["value"]).to include("input plugin")
      end

      it "shows common options" do
        result = provider.hover(uri, 1, 4)

        expect(result["contents"]["value"]).to include("codec")
      end
    end

    context "on option name" do
      let(:config) { "input {\n  stdin {\n    codec => plain\n  }\n}" }

      before { document_manager.open(uri, config, 1) }

      it "returns option documentation" do
        result = provider.hover(uri, 2, 6)

        expect(result).not_to be_nil
        expect(result["contents"]["value"]).to include("codec")
        expect(result["contents"]["value"]).to include("The codec for input data")
      end

      it "shows type and default" do
        result = provider.hover(uri, 2, 6)

        content = result["contents"]["value"]
        expect(content).to include("Type")
        expect(content).to include("Default")
      end
    end

    context "on whitespace or punctuation" do
      let(:config) { "input { }" }

      before { document_manager.open(uri, config, 1) }

      it "returns nil" do
        result = provider.hover(uri, 0, 6)  # On space
        expect(result).to be_nil
      end
    end

    context "on unknown word" do
      let(:config) { "# some comment with unknown word" }

      before { document_manager.open(uri, config, 1) }

      it "returns nil" do
        result = provider.hover(uri, 0, 15)
        expect(result).to be_nil
      end
    end
  end

  describe "hover content format" do
    let(:config) { "input {\n  stdin {\n  }\n}" }

    before { document_manager.open(uri, config, 1) }

    it "returns markdown format" do
      result = provider.hover(uri, 1, 4)

      expect(result["contents"]["kind"]).to eq("markdown")
    end

    it "includes example code" do
      result = provider.hover(uri, 1, 4)

      content = result["contents"]["value"]
      expect(content).to include("```logstash")
      expect(content).to include("```")
    end
  end

  describe "deprecated options" do
    let(:mock_plugin_with_deprecated) do
      Class.new do
        def self.config_name
          "deprecated_test"
        end

        def self.get_config
          {
            "old_option" => { :validate => :string, :deprecated => true, :description => "Old option" }
          }
        end
      end
    end

    before do
      allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:filter).and_return([mock_plugin_with_deprecated])
      schema_provider.refresh!
    end

    let(:config) { "filter {\n  deprecated_test {\n    old_option => test\n  }\n}" }

    before { document_manager.open(uri, config, 1) }

    it "shows deprecation warning" do
      result = provider.hover(uri, 2, 6)

      expect(result).not_to be_nil
      expect(result["contents"]["value"]).to include("Deprecated")
    end
  end
end
