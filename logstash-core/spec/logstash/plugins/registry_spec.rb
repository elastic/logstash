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
require "logstash/plugins/registry"
require "logstash/inputs/base"

# use a dummy NOOP input to test plugin registry
class LogStash::Inputs::Dummy < LogStash::Inputs::Base
  config_name "dummy"

  def register; end
end

class LogStash::Inputs::NewPlugin < LogStash::Inputs::Base
  config_name "new_plugin"

  def register; end
end

describe LogStash::Plugins::Registry do
  let(:alias_registry) { nil }
  let(:registry) { described_class.new alias_registry }

  context "when loading installed plugins" do
    let(:alias_registry) { Java::org.logstash.plugins.AliasRegistry.new({["input", "alias_std_input"] => "stdin"}) }
    let(:plugin) { double("plugin") }

    it "should return the expected class" do
      klass = registry.lookup("input", "stdin")
      expect(klass).to eq(LogStash::Inputs::Stdin)
    end

    it "should load an aliased ruby plugin" do
      klass = registry.lookup("input", "alias_std_input")
      expect(klass).to eq(LogStash::Inputs::Stdin)
    end

    it "should raise an error if can not find the plugin class" do
      expect { registry.lookup("input", "do-not-exist-elastic") }.to raise_error(LoadError)
    end

    it "should load from registry is already load" do
      expect(registry.exists?(:input, "stdin")).to be_falsey
      expect { registry.lookup("input", "new_plugin") }.to change { registry.size }.by(1)
      expect { registry.lookup("input", "new_plugin") }.not_to change { registry.size }
    end

    context "when loading installed plugin that overrides an alias" do
      let(:alias_registry) { Java::org.logstash.plugins.AliasRegistry.new({["input", "dummy"] => "new_plugin"}) }

      it 'should load the concrete implementation instead of resolving the alias' do
        klass = registry.lookup("input", "dummy")
        expect(klass).to eq(LogStash::Inputs::Dummy)
      end
    end
  end

  context "when loading code defined plugins" do
    let(:alias_registry) { Java::org.logstash.plugins.AliasRegistry.new({["input", "alias_input"] => "new_plugin"}) }

    it "should return the expected class" do
      klass = registry.lookup("input", "dummy")
      expect(klass).to eq(LogStash::Inputs::Dummy)
    end

    it "should return the expected class also for aliased plugins" do
      klass = registry.lookup("input", "alias_input")
      expect(klass).to eq(LogStash::Inputs::NewPlugin)
    end

    it "should return the expected class also for alias-targeted plugins" do
      klass = registry.lookup("input", "new_plugin")
      expect(klass).to eq(LogStash::Inputs::NewPlugin)
    end
  end

  context "when plugin is not installed and not defined" do
    it "should raise an error" do
      expect { registry.lookup("input", "elastic") }.to raise_error(LoadError)
    end
  end

  context "when loading plugin manually configured" do
    let(:simple_plugin) { Class.new }

    it "should return the plugin" do
      expect { registry.lookup("filter", "simple_plugin") }.to raise_error(LoadError)
      registry.add(:filter, "simple_plugin", simple_plugin)
      expect(registry.lookup("filter", "simple_plugin")).to eq(simple_plugin)
    end

    it "should be possible to remove the plugin" do
      registry.add(:filter, "simple_plugin", simple_plugin)
      expect(registry.lookup("filter", "simple_plugin")).to eq(simple_plugin)
      registry.remove(:filter, "simple_plugin")
      expect { registry.lookup("filter", "simple_plugin") }.to raise_error(LoadError)
    end

    it "doesn't add multiple time the same plugin" do
      plugin1 = Class.new
      plugin2 = Class.new

      registry.add(:filter, "simple_plugin", plugin1)
      registry.add(:filter, "simple_plugin", plugin2)

      expect(registry.plugins_with_type(:filter)).to include(plugin1)
      expect(registry.plugins_with_type(:filter).size).to eq(1)
    end

    it "allow you find plugin by type" do
      registry.add(:filter, "simple_plugin", simple_plugin)

      expect(registry.plugins_with_type(:filter)).to include(simple_plugin)
      expect(registry.plugins_with_type(:modules)).to match([])
    end
  end
end
