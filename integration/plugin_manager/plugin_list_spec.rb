# Encoding: utf-8
require_relative "../spec_helper"

describe "bin/plugin list" do
  context "without a specific plugin" do
    it "display a list of plugins" do
      result = command("bin/plugin list")
      expect(result.exit_status).to eq(0)
      expect(result.stdout.split("\n").size).to be > 1
    end

    it "display a list of installed plugins" do
      result = command("bin/plugin list --installed")
      expect(result.exit_status).to eq(0)
      expect(result.stdout.split("\n").size).to be > 1
    end

    it "list the plugins with their versions" do
      result = command("bin/plugin list --verbose")
      result.stdout.split("\n").each do |plugin|
        expect(plugin).to match(/^logstash-\w+-\w+\s\(\d+\.\d+.\d+\)/)
      end
      expect(result.exit_status).to eq(0)
    end
  end

  context "with a specific plugin" do
    let(:plugin_name) { "logstash-input-stdin" }
    it "list the plugin and display the plugin name" do
      result = command("bin/plugin list #{plugin_name}")
      expect(result.stdout).to match(/^#{plugin_name}$/)
      expect(result.exit_status).to eq(0)
    end

    it "list the plugin with his version" do
      result = command("bin/plugin list --verbose #{plugin_name}")
      expect(result.stdout).to match(/^#{plugin_name} \(\d+\.\d+.\d+\)/)
      expect(result.exit_status).to eq(0)
    end
  end
end
