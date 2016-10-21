# encoding: utf-8
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
  let(:registry) { described_class.new }

  context "when loading installed plugins" do
    let(:plugin) { double("plugin") }

    it "should return the expected class" do
      klass = registry.lookup("input", "stdin")
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
  end

  context "when loading code defined plugins" do
    it "should return the expected class" do
      klass = registry.lookup("input", "dummy")
      expect(klass).to eq(LogStash::Inputs::Dummy)
    end
  end

  context "when plugin is not installed and not defined" do
    it "should raise an error" do
      expect { registry.lookup("input", "elastic") }.to raise_error(LoadError)
    end
  end

  context "when loading plugin manually configured" do
    it "should return the plugin" do
      class SimplePlugin
      end

      expect { registry.lookup("filter", "simple_plugin") }.to raise_error(LoadError)
      registry.add(:filter, "simple_plugin", SimplePlugin)
      expect(registry.lookup("filter", "simple_plugin")).to eq(SimplePlugin)
    end
  end
end
