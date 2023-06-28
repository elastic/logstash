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

require "pluginmanager/pack_installer/local"
require "stud/temporary"
require "fileutils"

describe LogStash::PluginManager::PackInstaller::Local do
  subject { described_class.new(local_file) }

  context "when the local file doesn't exist" do
    let(:local_file) { ::File.join(Stud::Temporary.pathname, Time.now.to_s.to_s) }

    it "raises an exception" do
      expect { subject.execute }.to raise_error(LogStash::PluginManager::FileNotFoundError)
    end
  end

  context "when the local file exist" do
    context "when the file has the wrong extension" do
      let(:local_file) { Stud::Temporary.file.path }

      it "raises a InvalidPackError" do
        expect { subject.execute }.to raise_error(LogStash::PluginManager::InvalidPackError, /Invalid format/)
      end
    end

    context "when there is an error when the zip get uncompressed" do
      let(:local_file) do
        directory = Stud::Temporary.pathname
        FileUtils.mkdir_p(directory)
        p = ::File.join(directory, "#{Time.now.to_i.to_s}.zip")
        FileUtils.touch(p)
        p
      end

      it "raises a InvalidPackError" do
        expect { subject.execute }.to raise_error(LogStash::PluginManager::InvalidPackError, /Cannot uncompress the zip/)
      end
    end

    context "when the file doesnt have plugins in it" do
      let(:local_file) { ::File.join(::File.dirname(__FILE__), "..", "..", "..", "support", "pack", "empty-pack.zip") }

      it "raise an Invalid pack" do
        expect { subject.execute }.to raise_error(LogStash::PluginManager::InvalidPackError, /The pack must contains at least one plugin/)
      end
    end

    context "when the pack is valid" do
      let(:local_file) { ::File.join(::File.dirname(__FILE__), "..", "..", "..", "support", "pack", "valid-pack.zip") }

      it "install the gems" do
        expect(::Bundler::LogstashInjector).to receive(:inject!).with(be_kind_of(LogStash::PluginManager::PackInstaller::Pack)).and_return([])

        expect(::LogStash::PluginManager::GemInstaller).to receive(:install).with(/logstash-input-packtest-/, anything)
        expect(::LogStash::PluginManager::GemInstaller).to receive(:install).with(/logstash-input-packtestdep-/, anything)

        expect { subject.execute }.not_to raise_error
      end
    end
  end
end
