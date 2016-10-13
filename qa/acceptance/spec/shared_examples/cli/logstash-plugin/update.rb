# encoding: utf-8
require_relative "../../../spec_helper"
require "logstash/version"

shared_examples "logstash update" do |logstash|
  describe "logstash-plugin update on #{logstash.hostname}" do
    before :each do
      logstash.install({:version => LOGSTASH_VERSION})
    end

    after :each do
      logstash.uninstall
    end

    let(:plugin_name) { "logstash-filter-qatest" }
    let(:previous_version) { "0.1.0" }

    before do
      logstash.run_command_in_path("bin/logstash-plugin install --no-verify --version #{previous_version} #{plugin_name}")
      # Logstash wont update when we have a pinned versionin the gemfile so we remove them
      logstash.replace_in_gemfile(',[[:space:]]"0.1.0"', "")
      expect(logstash).to have_installed?(plugin_name, previous_version)
    end

    context "update a specific plugin" do
      it "has executed succesfully" do
        cmd = logstash.run_command_in_path("bin/logstash-plugin update --no-verify #{plugin_name}")
        expect(cmd.stdout).to match(/Updating #{plugin_name}/)
        expect(logstash).not_to have_installed?(plugin_name, previous_version)
      end
    end

    context "update all the plugins" do
      it "has executed succesfully" do
        logstash.run_command_in_path("bin/logstash-plugin update --no-verify")
        expect(logstash).to have_installed?(plugin_name, "0.1.1")
      end
    end
  end
end
