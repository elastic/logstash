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

require "pluginmanager/gem_installer"
require "pluginmanager/ui"
require "stud/temporary"
require "rubygems/specification"
require "fileutils"
require "ostruct"

describe LogStash::PluginManager::GemInstaller do
  let(:plugin_name) { "logstash-input-packtest-0.0.1" }
  let(:simple_gem) { ::File.join(::File.dirname(__FILE__), "..", "..", "support", "pack", "valid-pack", "logstash", "valid-pack", "#{plugin_name}.gem") }

  subject { described_class }
   let(:gem_home) { LogStash::Environment.logstash_gem_home }
   # Clean up installed gems after each test
   after(:each) do
     spec_file = ::File.join(gem_home, "specifications", "#{plugin_name}.gemspec")
     FileUtils.rm_f(spec_file) if ::File.exist?(spec_file)
     gem_dir = ::File.join(gem_home, "gems", plugin_name)
     FileUtils.rm_rf(gem_dir) if Dir.exist?(gem_dir)
     cache_file = ::File.join(gem_home, "cache", "#{plugin_name}.gem")
     FileUtils.rm_f(cache_file) if ::File.exist?(cache_file)
   end

  it "install the specifications in the spec dir" do
    subject.install(simple_gem, false)
    spec_file = ::File.join(gem_home, "specifications", "#{plugin_name}.gemspec")
    expect(::File.exist?(spec_file)).to be_truthy
    expect(::File.size(spec_file)).to be > 0
  end

  it "install the gem in the gems dir" do
    subject.install(simple_gem, false)
    gem_dir = ::File.join(gem_home, "gems", plugin_name)
    expect(Dir.exist?(gem_dir)).to be_truthy
  end

  context "post_install_message" do
    let(:message) { "Hello from the friendly pack" }

    context "when present" do
      let(:plugin_name) { 'logstash-input-packtest_pim-0.0.1' }

      context "when we want the message" do
        it "display the message" do
          expect(subject.install(simple_gem, true)).to eq(message)
        end
      end

      context "when we dont want the message" do
        it "doesn't display the message" do
          expect(subject.install(simple_gem, false)).to be_nil
        end
      end
    end

    context "when not present" do
      context "when we don't want the message" do
        it "doesn't display the message" do
          expect(LogStash::PluginManager.ui).not_to receive(:info).with(message)
          subject.install(simple_gem, true)
        end
      end
    end
  end
end
