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
require "logstash/lsp/document_manager"

describe LogStash::Lsp::DocumentManager do
  subject(:manager) { described_class.new }

  let(:uri) { "file:///test/pipeline.conf" }
  let(:sample_config) do
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

  describe "document lifecycle" do
    it "opens a document" do
      manager.open(uri, sample_config, 1)

      expect(manager.open?(uri)).to be true
      expect(manager.get_content(uri)).to eq(sample_config)
      expect(manager.get_version(uri)).to eq(1)
    end

    it "updates a document" do
      manager.open(uri, "old content", 1)
      manager.update(uri, "new content", 2)

      expect(manager.get_content(uri)).to eq("new content")
      expect(manager.get_version(uri)).to eq(2)
    end

    it "closes a document" do
      manager.open(uri, sample_config, 1)
      manager.close(uri)

      expect(manager.open?(uri)).to be false
      expect(manager.get_content(uri)).to be_nil
    end
  end

  describe "#position_to_offset" do
    before { manager.open(uri, sample_config, 1) }

    it "converts line 0, character 0 to offset 0" do
      offset = manager.position_to_offset(uri, 0, 0)
      expect(offset).to eq(0)
    end

    it "converts position within first line" do
      # "input {" - character 5 is 'i' in input -> 't'
      offset = manager.position_to_offset(uri, 0, 5)
      expect(sample_config[offset]).to eq(' ')
    end

    it "converts position on second line" do
      # Line 1 is "  stdin {"
      offset = manager.position_to_offset(uri, 1, 2)
      expect(sample_config[offset]).to eq('s')
    end

    it "returns nil for invalid line" do
      offset = manager.position_to_offset(uri, 999, 0)
      expect(offset).to be_nil
    end

    it "clamps character to line length" do
      offset = manager.position_to_offset(uri, 0, 9999)
      # Should clamp to end of "input {"
      expect(offset).to eq(7)
    end
  end

  describe "#offset_to_position" do
    before { manager.open(uri, sample_config, 1) }

    it "converts offset 0 to line 0, character 0" do
      pos = manager.offset_to_position(uri, 0)
      expect(pos).to eq({ line: 0, character: 0 })
    end

    it "converts offset within first line" do
      pos = manager.offset_to_position(uri, 5)
      expect(pos).to eq({ line: 0, character: 5 })
    end

    it "converts offset on second line" do
      # First line "input {" is 7 chars + 1 newline = 8
      pos = manager.offset_to_position(uri, 10)
      expect(pos[:line]).to eq(1)
      expect(pos[:character]).to eq(2)
    end

    it "returns nil for negative offset" do
      pos = manager.offset_to_position(uri, -1)
      expect(pos).to be_nil
    end
  end

  describe "#get_word_at" do
    before { manager.open(uri, sample_config, 1) }

    it "extracts word at cursor" do
      # Line 0 "input {" - character 2 is in "input"
      word = manager.get_word_at(uri, 0, 2)
      expect(word[:word]).to eq("input")
    end

    it "returns nil when not on a word" do
      # Line 0 "input {" - character 6 is on space or brace
      word = manager.get_word_at(uri, 0, 6)
      expect(word).to be_nil
    end

    it "handles hyphenated words" do
      manager.open(uri, "input { stdin-test { } }", 1)
      word = manager.get_word_at(uri, 0, 10)
      expect(word[:word]).to eq("stdin-test")
    end
  end

  describe "#get_context_at" do
    before { manager.open(uri, sample_config, 1) }

    it "returns root context outside any block" do
      manager.open(uri, "# comment\n", 1)
      context = manager.get_context_at(uri, 0, 0)
      expect(context[:type]).to eq(:root)
    end

    it "returns plugin_name context inside section block" do
      # Position after "input {\n  " - expecting plugin name
      context = manager.get_context_at(uri, 1, 2)
      expect(context[:type]).to eq(:plugin_name)
      expect(context[:section]).to eq(:input)
    end

    it "returns attribute_name context inside plugin block" do
      # Position inside stdin { } on empty line
      config = "input {\n  stdin {\n    \n  }\n}"
      manager.open(uri, config, 1)
      context = manager.get_context_at(uri, 2, 4)
      expect(context[:type]).to eq(:attribute_name)
      expect(context[:section]).to eq(:input)
    end

    it "returns attribute_value context after =>" do
      config = "input {\n  stdin {\n    codec => \n  }\n}"
      manager.open(uri, config, 1)
      context = manager.get_context_at(uri, 2, 14)
      expect(context[:type]).to eq(:attribute_value)
    end

    it "identifies current section type" do
      context = manager.get_context_at(uri, 1, 2)
      expect(context[:section]).to eq(:input)

      # Line 6 is inside filter section
      context = manager.get_context_at(uri, 6, 2)
      expect(context[:section]).to eq(:filter)
    end

    it "identifies current plugin name" do
      # Inside grok plugin
      context = manager.get_context_at(uri, 7, 4)
      expect(context[:plugin]).to eq("grok")
    end
  end

  describe "edge cases" do
    it "handles empty document" do
      manager.open(uri, "", 1)
      context = manager.get_context_at(uri, 0, 0)
      expect(context[:type]).to eq(:root)
    end

    it "handles document with only whitespace" do
      manager.open(uri, "   \n   \n", 1)
      context = manager.get_context_at(uri, 1, 2)
      expect(context[:type]).to eq(:root)
    end

    it "handles unopened document" do
      content = manager.get_content("file:///nonexistent.conf")
      expect(content).to be_nil
    end
  end
end
