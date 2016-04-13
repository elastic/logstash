# encoding: utf-8
require "spec_helper"
require "logstash/plugins/registry"
require "logstash/inputs/base"

# use a dummy NOOP input to test plugin registry
class LogStash::Inputs::Dummy < LogStash::Inputs::Base
  config_name "dummy"

  def register; end

end

describe LogStash::Registry do

  let(:registry) { described_class.instance }

  context "when loading installed plugins" do

    let(:plugin) { double("plugin") }

    it "should return the expected class" do
      klass = registry.lookup("input", "stdin")
      expect(klass).to eq(LogStash::Inputs::Stdin)
    end

    it "should raise an error if can not find the plugin class" do
      expect(LogStash::Registry::Plugin).to receive(:new).with("input", "elastic").and_return(plugin)
      expect(plugin).to receive(:path).and_return("logstash/input/elastic").twice
      expect(plugin).to receive(:installed?).and_return(true)
      expect { registry.lookup("input", "elastic") }.to raise_error(LoadError)
    end

    it "should load from registry is already load" do
      registry.lookup("input", "stdin")
      expect(registry).to receive(:registered?).and_return(true).once
      registry.lookup("input", "stdin")
      internal_registry = registry.instance_variable_get("@registry")
      expect(internal_registry).to include("logstash/inputs/stdin" => LogStash::Inputs::Stdin)
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

end

