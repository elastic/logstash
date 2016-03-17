# Encoding: utf-8
require_relative "../spec_helper"

describe "update" do
  let(:plugin_name) { "logstash-input-stdin" }
  let(:previous_version) { "2.0.1" }

  before do
    command("bin/plugin install --version #{previous_version} #{plugin_name}")
    cmd = command("bin/plugin list --verbose #{plugin_name}")
    expect(cmd.stdout).to match(/#{plugin_name} \(#{previous_version}\)/)
  end

  context "update a specific plugin" do
    subject { command("bin/plugin update #{plugin_name}") }

    it "has executed succesfully" do
      expect(subject.exit_status).to eq(0)
      expect(subject.stdout).to match(/Updating #{plugin_name}/)
    end
  end

  context "update all the plugins" do
    subject { command("bin/plugin update") }

    it "has executed succesfully" do
      expect(subject.exit_status).to eq(0)
      cmd = command("bin/plugin list --verbose #{plugin_name}").stdout
      expect(cmd).to match(/logstash-input-stdin \(#{LogStashTestHelpers.latest_version(plugin_name)}\)/)
    end
  end
end
