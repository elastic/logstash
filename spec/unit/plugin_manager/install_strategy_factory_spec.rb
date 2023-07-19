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

require "pluginmanager/install_strategy_factory"

describe LogStash::PluginManager::InstallStrategyFactory do
  subject { described_class }

  context "when the plugins args is valid" do
    let(:plugins_args) { ["logstash-pack-mega"] }

    it "returns the first matched strategy" do
      success = double("urifetch success")

      expect(LogStash::PluginManager::PackFetchStrategy::Uri).to receive(:get_installer_for).with(plugins_args.first).and_return(success)
      expect(subject.create(plugins_args)).to eq(success)
    end

    it "returns the matched strategy" do
      success = double("elastic xpack success")

      expect(LogStash::PluginManager::PackFetchStrategy::Repository).to receive(:get_installer_for).with(plugins_args.first).and_return(success)
      expect(subject.create(plugins_args)).to eq(success)
    end

    it "return nil when no strategy matches" do
      expect(LogStash::PluginManager::PackFetchStrategy::Uri).to receive(:get_installer_for).with(plugins_args.first).and_return(nil)
      expect(LogStash::PluginManager::PackFetchStrategy::Repository).to receive(:get_installer_for).with(plugins_args.first).and_return(nil)
      expect(subject.create(plugins_args)).to be_falsey
    end
  end

  context "when the plugins args" do
    context "is an empty string" do
      let(:plugins_args) { [""] }

      it "returns no strategy matched" do
        expect(subject.create(plugins_args)).to be_falsey
      end
    end

    context "is nil" do
      let(:plugins_args) { [] }

      it "returns no strategy matched" do
        expect(subject.create(plugins_args)).to be_falsey
      end
    end
  end
end
