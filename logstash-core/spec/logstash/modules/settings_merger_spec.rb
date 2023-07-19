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
require "logstash/util/cloud_setting_id"
require "logstash/util/cloud_setting_auth"
require "logstash/modules/settings_merger"
require "logstash/util/password"
require "logstash/util/modules_setting_array"

class SubstituteSettingsForRSpec
  def initialize(hash = {}) @hash = hash; end
  def put(key, value) @hash[key] = value; end
  def get(key) @hash[key]; end
end

describe LogStash::Modules::SettingsMerger do
  describe "#merge" do
    let(:cli) { LogStash::Util::ModulesSettingArray.new [{"name" => "mod1", "var.input.tcp.port" => "3333"}, {"name" => "mod2"}] }
    let(:yml) {[{"name" => "mod1", "var.input.tcp.port" => 2222, "var.kibana.username" => "rupert", "var.kibana.password" => "fotherington"}, {"name" => "mod3", "var.input.tcp.port" => 4445}]}
    subject(:results) { described_class.merge(cli, yml) }
    it "merges cli overwriting any common fields in yml" do
      expect(results).to be_a(Array)
      expect(results.size).to eq(3)
      expect(results[0]["name"]).to eq("mod1")
      expect(results[0]["var.input.tcp.port"]).to eq("3333")
      expect(results[0]["var.kibana.username"]).to eq("rupert")
      expect(results[1]["name"]).to eq("mod2")
      expect(results[2]["name"]).to eq("mod3")
      expect(results[2]["var.input.tcp.port"]).to eq(4445)
    end
  end

  describe "#merge_kibana_auth" do
    before do
      described_class.merge_kibana_auth!(mod_settings)
    end

    context 'only elasticsearch username and password is set' do
      let(:mod_settings) { {"name" => "mod1", "var.input.tcp.port" => 2222, "var.elasticsearch.username" => "rupert", "var.elasticsearch.password" => "fotherington" } }
      it "sets kibana username and password" do
        expect(mod_settings["var.elasticsearch.username"]).to eq("rupert")
        expect(mod_settings["var.elasticsearch.password"]).to eq("fotherington")
        expect(mod_settings["var.kibana.username"]).to eq("rupert")
        expect(mod_settings["var.kibana.password"]).to eq("fotherington")
      end
    end

    context 'elasticsearch and kibana usernames and passwords are set' do
      let(:mod_settings) { {"name" => "mod1", "var.input.tcp.port" => 2222, "var.elasticsearch.username" => "rupert", "var.elasticsearch.password" => "fotherington",
                                                               "var.kibana.username" => "davey", "var.kibana.password" => "stott"} }

      it "keeps existing kibana username and password" do
        expect(mod_settings["var.elasticsearch.username"]).to eq("rupert")
        expect(mod_settings["var.elasticsearch.password"]).to eq("fotherington")
        expect(mod_settings["var.kibana.username"]).to eq("davey")
        expect(mod_settings["var.kibana.password"]).to eq("stott")
      end
    end
  end

  describe "#merge_cloud_settings" do
    let(:cloud_id) { LogStash::Util::CloudSettingId.new("label:dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy") }
    let(:cloud_auth) { LogStash::Util::CloudSettingAuth.new("elastix:bigwhoppingfairytail") }
    let(:mod_settings) { {} }

    context "when both are supplied" do
      let(:expected_table) do
        {
          "var.kibana.scheme" => "https",
          "var.kibana.host" => "identifier.us-east-1.aws.found.io:443",
          "var.elasticsearch.hosts" => "https://notareal.us-east-1.aws.found.io:443",
          "var.elasticsearch.username" => "elastix",
          "var.kibana.username" => "elastix"
        }
      end
      let(:ls_settings) { SubstituteSettingsForRSpec.new({"cloud.id" => cloud_id, "cloud.auth" => cloud_auth}) }

      before do
        described_class.merge_cloud_settings(mod_settings, ls_settings)
      end

      it "adds entries to module settings" do
        expected_table.each do |key, expected|
          expect(mod_settings[key]).to eq(expected)
        end
        expect(mod_settings["var.elasticsearch.password"].value).to eq("bigwhoppingfairytail")
        expect(mod_settings["var.kibana.password"].value).to eq("bigwhoppingfairytail")
      end
    end

    context "when cloud.id is supplied" do
      let(:expected_table) do
        {
          "var.kibana.scheme" => "https",
          "var.kibana.host" => "identifier.us-east-1.aws.found.io:443",
          "var.elasticsearch.hosts" => "https://notareal.us-east-1.aws.found.io:443",
        }
      end
      let(:ls_settings) { SubstituteSettingsForRSpec.new({"cloud.id" => cloud_id}) }

      before do
        described_class.merge_cloud_settings(mod_settings, ls_settings)
      end

      it "adds entries to module settings" do
        expected_table.each do |key, expected|
          expect(mod_settings[key]).to eq(expected)
        end
      end
    end

    context "when only cloud.auth is supplied" do
      let(:ls_settings) { SubstituteSettingsForRSpec.new({"cloud.auth" => cloud_auth}) }
      it "should raise an error" do
        expect { described_class.merge_cloud_settings(mod_settings, ls_settings) }.to raise_exception(ArgumentError)
      end
    end

    context "when neither cloud.id nor cloud.auth is supplied" do
      let(:ls_settings) { SubstituteSettingsForRSpec.new() }
      it "should do nothing" do
        expect(mod_settings).to be_empty
      end
    end
  end

  describe "#format_module_settings" do
    let(:before_hash) { {"foo" => "red", "bar" => "blue", "qux" => "pink"} }
    let(:after_hash) { {"foo" => "red", "bar" => "steel-blue", "baz" => LogStash::Util::Password.new("cyan"), "qux" => nil} }
    subject(:results) { described_class.format_module_settings(before_hash, after_hash) }
    it "yields an array of formatted lines for ease of logging" do
      expect(results.size).to eq(after_hash.size + 2)
      expect(results.first).to eq("-------- Module Settings ---------")
      expect(results.last).to eq("-------- Module Settings ---------")
      expect(results[1]).to eq("foo: 'red'")
      expect(results[2]).to eq("bar: 'steel-blue', was: 'blue'")
      expect(results[3]).to eq("baz: '<password>', was: ''")
      expect(results[4]).to eq("qux: '', was: 'pink'")
    end
  end
end
