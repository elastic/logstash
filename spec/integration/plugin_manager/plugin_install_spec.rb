# Encoding: utf-8
require_relative "../spec_helper"
require "fileutils"

context "bin/logstash-plugin install" do
  context "with a local gem" do
    let(:gem_name) { "logstash-input-wmi" }
    let(:local_gem) { gem_fetch(gem_name) }

    it "install the gem succesfully" do
      result = command("bin/logstash-plugin install --no-verify #{local_gem}")
      expect(result.exit_status).to eq(0)
      expect(result.stdout).to match(/^Installing\s#{gem_name}\nInstallation\ssuccessful$/)
    end
  end

  context "when the plugin exist" do
    let(:plugin_name) { "logstash-input-drupal_dblog" }

    it "sucessfully install" do
      result = command("bin/logstash-plugin install #{plugin_name}")
      expect(result.exit_status).to eq(0)
      expect(result.stdout).to match(/^Validating\s#{plugin_name}\nInstalling\s#{plugin_name}\nInstallation\ssuccessful$/)
    end

    it "allow to install a specific version" do
      version = "2.0.2"
      result = command("bin/logstash-plugin install --version 2.0.2 #{plugin_name}")
      expect(result.exit_status).to eq(0)
      expect(result.stdout).to match(/^Validating\s#{plugin_name}-#{version}\nInstalling\s#{plugin_name}\nInstallation\ssuccessful$/)
    end
  end

  context "when the plugin doesn't exist" do
    it "fails to install" do
      result = command("bin/logstash-plugin install --no-verify logstash-output-impossible-plugin")
      expect(result.exit_status).to eq(1)
      expect(result.stderr).to match(/Installation Aborted, message: Could not find gem/)
    end
  end
end
