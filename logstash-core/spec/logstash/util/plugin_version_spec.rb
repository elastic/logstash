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
require "logstash/util/plugin_version"

describe "LogStash::Util::PluginVersion" do
  subject { LogStash::Util::PluginVersion }

  context "#find_version!" do
    let(:gem)     { "bundler" }

    it 'raises an PluginNoVersionError if we cant find the plugin in the gem path' do
      dummy_name = 'this-character-doesnt-exist-in-the-marvel-universe'
      expect { subject.find_version!(dummy_name) }.to raise_error(LogStash::PluginNoVersionError)
    end

    it 'returns the version of the gem' do
      expect { subject.find_version!(gem) }.not_to raise_error
    end

    context "with a pre release gem" do
      it 'return the version of the gem' do
        # Gem::Specification.find_by_name return nil if the gem is not activated, as for
        # example the pre release ones.
        expect(Gem::Specification).to receive(:find_by_name).and_return(nil)
        expect { subject.find_version!(gem) }.not_to raise_error
      end
    end
  end

  context "#new" do
    it 'accepts a Gem::Version instance as argument' do
      version = Gem::Version.new('1.0.1')
      expect(subject.new(version).to_s).to eq(version.to_s)
    end

    it 'accepts an array for defining the version' do
      version = subject.new(1, 0, 2)
      expect(version.to_s).to eq('1.0.2')
    end
  end

  context "When comparing instances" do
    it 'allow to check if the version is newer or older' do
      old_version = subject.new(0, 1, 0)
      new_version = subject.new(1, 0, 1)

      expect(old_version).to be < new_version
      expect(old_version).to be <= new_version
      expect(new_version).to be > old_version
      expect(new_version).to be >= old_version
    end

    it 'return true if the version are equal' do
      version1 = subject.new(0, 1, 0)
      version2 = subject.new(0, 1, 0)

      expect(version1).to eq(version2)
    end
  end
end
