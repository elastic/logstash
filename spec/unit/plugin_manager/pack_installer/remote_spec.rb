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

require "pluginmanager/pack_installer/remote"
require "webmock/rspec"

describe LogStash::PluginManager::PackInstaller::Remote do
  let(:url) { "http://localhost:8888/mypackage.zip" }

  subject { described_class.new(url, LogStash::PluginManager::Utils::Downloader::SilentFeedback) }

  context "when the file exist remotely" do
    let(:content) { "around the world" }

    before do
      stub_request(:get, url).to_return(
        { :status => 200,
          :body => content,
          :headers => {}}
      )
    end

    it "download the file and do a local install" do
      local_installer = double("LocalInstaller")

      expect(local_installer).to receive(:execute)
      expect(LogStash::PluginManager::PackInstaller::Local).to receive(:new).with(be_kind_of(String)).and_return(local_installer)

      subject.execute
    end
  end

  context "when the file doesn't exist remotely" do
    before do
      stub_request(:get, url).to_return({ :status => 404 })
    end

    it "raises and exception" do
      expect { subject.execute }.to raise_error(LogStash::PluginManager::FileNotFoundError, /#{url}/)
    end
  end
end
