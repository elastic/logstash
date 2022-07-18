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

require "logstash/modules/logstash_config"

describe LogStash::Modules::LogStashConfig do
  let(:module_name) { "testing" }
  let(:mod) { instance_double("module", :directory => Stud::Temporary.directory, :module_name => module_name) }
  let(:settings) { {"var.logstash.testing.pants" => "fancy", "var.elasticsearch.password" => LogStash::Util::Password.new('correct_horse_battery_staple') }}
  subject { described_class.new(mod, settings) }

  describe "configured inputs" do
    context "when no inputs is send" do
      it "returns the default" do
        expect(subject.configured_inputs(["kafka"])).to include("kafka")
      end
    end

    context "when inputs are send" do
      let(:settings) { { "var.inputs" => "tcp" } }

      it "returns the configured inputs" do
        expect(subject.configured_inputs(["kafka"])).to include("tcp")
      end

      context "when alias is specified" do
        let(:settings) { { "var.inputs" => "smartconnector" } }

        it "returns the configured inputs" do
          expect(subject.configured_inputs(["kafka"], { "smartconnector" => "tcp"  })).to include("tcp", "smartconnector")
        end
      end
    end
  end

  describe "array to logstash array string" do
    it "return an escaped string" do
      expect(subject.array_to_string(["hello", "ninja"])).to eq("['hello', 'ninja']")
    end
  end

  describe 'elasticsearch_config_output' do
    let(:args) { nil }
    let(:config) { subject.elasticsearch_output_config(*args) }
    it 'should put the password in correctly' do
      expect(config).to include("password => \"correct_horse_battery_staple\"")
    end
    it 'appends the timestamp expression to the index name' do
      expect(config).to include("index => \"#{module_name}-%{+YYYY.MM.dd}\"")
    end
    context "when index_suffix is customized" do
      let(:custom_suffix) { "-new_suffix" }
      let(:args) { ["my_custom", custom_suffix] }
      it 'the index name uses the custom suffix instead' do
        expect(config).to include("index => \"#{module_name}#{custom_suffix}\"")
      end
    end
  end

  describe "alias modules options" do
    let(:alias_table) do
      { "var.logstash.testing" => "var.logstash.better" }
    end

    before do
      subject.alias_settings_keys!(alias_table)
    end

    it "allow to retrieve settings" do
      expect(subject.setting("var.logstash.better.pants", "dont-exist")).to eq("fancy")
    end

    it "allow to retrieve settings with the original name" do
      expect(subject.setting("var.logstash.testing.pants", "dont-exist")).to eq("fancy")
    end
  end
end
