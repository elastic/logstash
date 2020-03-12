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

require "pluginmanager/pack_fetch_strategy/uri"
require "stud/temporary"

describe LogStash::PluginManager::PackFetchStrategy::Uri do
  subject { described_class }
  context "when we dont have URI path" do
    let(:plugin_path) { "logstash-input-elasticsearch" }

    it "doesnt return an installer" do
      expect(subject.get_installer_for(plugin_path)).to be_falsey
    end
  end

  context "we have another URI scheme than file or http" do
    let(:plugin_path) { "ftp://localhost:8888/my-pack.zip" }

    it "doesnt return an installer" do
      expect(subject.get_installer_for(plugin_path)).to be_falsey
    end
  end

  context "we have an invalid URI scheme" do
    let(:plugin_path) { "inv://localhost:8888/my-pack.zip" }

    it "doesnt return an installer" do
      expect(subject.get_installer_for(plugin_path)).to be_falsey
    end
  end

  context "when we have a local path" do
    let(:temporary_file) do
      f = Stud::Temporary.file
      f.write("hola")
      f.close
      f.path
    end

    # Windows safe way to produce a file: URI.
    let(:plugin_path) { URI.join("file:///" + File.absolute_path(temporary_file)).to_s }

    it "returns a `LocalInstaller`" do
      expect(subject.get_installer_for(plugin_path)).to be_kind_of(LogStash::PluginManager::PackInstaller::Local)
    end
  end

  context "when we have a remote path" do
    let(:plugin_path) { "http://localhost:8888/my-pack.zip" }

    it "returns a remote installer" do
      expect(subject.get_installer_for(plugin_path)).to be_kind_of(LogStash::PluginManager::PackInstaller::Remote)
    end
  end
end
