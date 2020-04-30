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

require "pluginmanager/offline_plugin_packager"
require "stud/temporary"
require "stud/try"
require "bootstrap/util/compress"
require "fileutils"
require "spec_helper"
require "webmock"
require "openssl"

def retrieve_packaged_plugins(path)
  Dir.glob(::File.join(path, "logstash", "*.gem"))
end

def retrieve_dependencies_gems(path)
  Dir.glob(::File.join(path, "logstash", "dependencies", "*.gem"))
end

describe LogStash::PluginManager::SpecificationHelpers do
  subject { described_class }

  context "when it find gems" do
    it "returns filtered results" do
      expect(subject.find_by_name_with_wildcards("logstash-filter-*").all? { |spec| spec.name =~ /logstash-filter-/ }).to be_truthy
    end
  end

  context "when it doesn't find gems" do
    it "doesnt return gemspecs" do
      expect(subject.find_by_name_with_wildcards("donotexistatall").size).to eq(0)
    end
  end
end

describe LogStash::PluginManager::OfflinePluginPackager do
  before do
    WebMock.allow_net_connect!
  end

  subject { described_class }

  let(:temporary_dir) { Stud::Temporary.pathname }
  let(:target) { ::File.join(temporary_dir, "my-pack.zip")}
  let(:extract_to) { Stud::Temporary.pathname }
  let(:retries_count) { 50 }
  let(:retries_exceptions) { [IOError, OpenSSL::SSL::SSLError] }

  context "when the plugins doesn't" do
    let(:plugins_args) { "idotnotexist" }

    it "raise an exception" do
      expect { subject.package(plugins_args, target) }.to raise_error(LogStash::PluginManager::PluginNotFoundError)
    end
  end

  context "when the plugins is a core gem" do
    %W(
    logstash-core
    logstash-core-plugin-api).each do |plugin_name|
      it "raise an exception with plugin: #{plugin_name}" do
        expect { subject.package(plugin_name, target) }.to raise_error(LogStash::PluginManager::UnpackablePluginError)
      end
    end
  end

  context "when the plugins exist" do
    before :all do
      Paquet.ui = Paquet::SilentUI
    end

    before do
      FileUtils.mkdir_p(temporary_dir)

      # Because this method will reach rubygems and can be unreliable at time on CI
      # we will retry any IOError a few times before giving up.
      Stud.try(retries_count.times, retries_exceptions)  { subject.package(plugins_args, target) }

      LogStash::Util::Zip.extract(target, extract_to)
    end

    context "one plugin specified" do
      let(:plugins_args) { ["logstash-input-stdin"] }

      it "creates a pack with the plugin" do
        try do
          expect(retrieve_packaged_plugins(extract_to).size).to eq(1)
          expect(retrieve_packaged_plugins(extract_to)).to include(/logstash-input-stdin/)
          expect(retrieve_dependencies_gems(extract_to).size).to be > 0
        end
      end
    end

    context "multiples plugins" do
      let(:plugins_args) { ["logstash-input-stdin", "logstash-input-beats"] }

      it "creates pack with the plugins" do
        try do
          expect(retrieve_packaged_plugins(extract_to).size).to eq(2)

          plugins_args.each do |plugin_name|
            expect(retrieve_packaged_plugins(extract_to)).to include(/#{plugin_name}/)
          end

          expect(retrieve_dependencies_gems(extract_to).size).to be > 0
        end
      end
    end

    context "with wildcards" do
      let(:plugins_args) { ["logstash-filter-x*"] }

      it "creates a pack with the plugins" do
        expect(retrieve_packaged_plugins(extract_to).size).to eq(LogStash::PluginManager::SpecificationHelpers.find_by_name_with_wildcards(plugins_args.first).size)

        retrieve_packaged_plugins(extract_to).each do |gem_file|
          expect(gem_file).to match(/logstash-filter-.+/)
        end

        expect(retrieve_dependencies_gems(extract_to).size).to be > 0
      end
    end

    context "with wildcards and normal plugins" do
      let(:plugins_args) { ["logstash-filter-x*", "logstash-input-beats"] }

      it "creates a pack with the plugins" do
        groups = retrieve_packaged_plugins(extract_to).group_by { |gem_file| ::File.basename(gem_file).split("-")[1] }

        expect(groups["filter"].size).to eq(LogStash::PluginManager::SpecificationHelpers.find_by_name_with_wildcards(plugins_args.first).size)

        groups["filter"].each do |gem_file|
          expect(gem_file).to match(/logstash-filter-.+/)
        end

        expect(groups["input"].size).to eq(1)
        expect(groups["input"]).to include(/logstash-input-beats/)

        expect(retrieve_dependencies_gems(extract_to).size).to be > 0
      end
    end
  end
end
