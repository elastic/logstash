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
require "logstash/lsp/schema_provider"

describe LogStash::Lsp::SchemaProvider do
  subject(:provider) { described_class.new }

  # Create a mock plugin class for testing
  let(:mock_plugin_class) do
    Class.new do
      def self.config_name
        "mock_plugin"
      end

      def self.get_config
        {
          "host" => { :validate => :string, :default => "localhost", :required => false },
          "port" => { :validate => :number, :default => 9200, :required => true },
          "ssl" => { :validate => :boolean, :default => false },
          "format" => { :validate => ["plain", "json"], :default => "plain" },
          "pattern" => { :validate => /^[a-z]+$/ }
        }
      end
    end
  end

  before do
    # Mock the plugin registry to return our test plugin
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).and_return([])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:input).and_return([mock_plugin_class])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:filter).and_return([])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:output).and_return([])
    allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:codec).and_return([])
  end

  describe "#plugin_names" do
    it "returns plugin names for a type" do
      names = provider.plugin_names(:input)
      expect(names).to include("mock_plugin")
    end

    it "returns empty array for unknown type" do
      names = provider.plugin_names(:unknown)
      expect(names).to eq([])
    end
  end

  describe "#plugin_options" do
    it "returns config options for a plugin" do
      options = provider.plugin_options(:input, "mock_plugin")

      expect(options).to have_key("host")
      expect(options).to have_key("port")
      expect(options).to have_key("ssl")
    end

    it "returns empty hash for unknown plugin" do
      options = provider.plugin_options(:input, "unknown_plugin")
      expect(options).to eq({})
    end
  end

  describe "#option_details" do
    it "returns details for a specific option" do
      details = provider.option_details(:input, "mock_plugin", "port")

      expect(details[:type]).to eq("number")
      expect(details[:default]).to eq(9200)
      expect(details[:required]).to eq(true)
    end

    it "normalizes string type" do
      details = provider.option_details(:input, "mock_plugin", "host")
      expect(details[:type]).to eq("string")
    end

    it "normalizes boolean type" do
      details = provider.option_details(:input, "mock_plugin", "ssl")
      expect(details[:type]).to eq("boolean")
    end

    it "normalizes enum types" do
      details = provider.option_details(:input, "mock_plugin", "format")
      expect(details[:type]).to be_a(Hash)
      expect(details[:type][:enum]).to eq(["plain", "json"])
    end

    it "normalizes regex types" do
      details = provider.option_details(:input, "mock_plugin", "pattern")
      expect(details[:type]).to be_a(Hash)
      expect(details[:type][:pattern]).to eq("^[a-z]+$")
    end

    it "returns nil for unknown option" do
      details = provider.option_details(:input, "mock_plugin", "unknown")
      expect(details).to be_nil
    end
  end

  describe "#plugin_exists?" do
    it "returns true for existing plugin" do
      expect(provider.plugin_exists?(:input, "mock_plugin")).to be true
    end

    it "returns false for non-existing plugin" do
      expect(provider.plugin_exists?(:input, "nonexistent")).to be false
    end
  end

  describe "#schema" do
    it "returns schema structure with all plugin types" do
      schema = provider.schema

      expect(schema).to have_key(:input)
      expect(schema).to have_key(:filter)
      expect(schema).to have_key(:output)
      expect(schema).to have_key(:codec)
    end

    it "caches the schema" do
      schema1 = provider.schema
      schema2 = provider.schema

      expect(schema1).to equal(schema2)
    end
  end

  describe "#refresh!" do
    it "clears the schema cache" do
      schema1 = provider.schema
      provider.refresh!

      # After refresh, a new schema should be built
      expect(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).at_least(:once).and_return([])
      provider.schema
    end
  end

  describe "option metadata" do
    it "marks common options" do
      # Create a plugin with common options
      plugin_with_common = Class.new do
        def self.config_name
          "plugin_with_common"
        end

        def self.get_config
          {
            "id" => { :validate => :string },
            "custom_option" => { :validate => :string }
          }
        end
      end

      allow(LogStash::PLUGIN_REGISTRY).to receive(:plugins_with_type).with(:filter).and_return([plugin_with_common])
      provider.refresh!

      id_details = provider.option_details(:filter, "plugin_with_common", "id")
      custom_details = provider.option_details(:filter, "plugin_with_common", "custom_option")

      expect(id_details[:common]).to be true
      expect(custom_details[:common]).to be false
    end
  end
end
