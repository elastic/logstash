# encoding: utf-8
require_relative "../../../spec_helper"
require "logstash/version"
require "fileutils"

shared_examples "logstash uninstall" do |logstash|
  describe "logstash uninstall on #{logstash.hostname}" do
    before :each do
      logstash.install({:version => LOGSTASH_VERSION})
    end

    after :each do
      logstash.uninstall
    end

    context "when the plugin isn't installed" do
      it "fails to uninstall it" do
        result = logstash.run_command_in_path("bin/logstash-plugin uninstall logstash-filter-qatest")
        expect(result.stderr).to match(/ERROR: Uninstall Aborted, message: This plugin has not been previously installed, aborting/)
      end
    end

    # Disabled because of this bug https://github.com/elastic/logstash/issues/5286
    xcontext "when the plugin is installed" do
      it "succesfully uninstall it" do
        result = logstash.run_command_in_path("bin/logstash-plugin install logstash-filter-qatest")
        expect(logstash).to have_installed?("logstash-filter-qatest")

        result = logstash.run_command_in_path("bin/logstash-plugin uninstall logstash-filter-qatest")
        expect(result.stdout).to match(/^Uninstalling logstash-filter-qatest/)
        expect(logstash).not_to have_installed?("logstash-filter-qatest")
      end
    end
  end
end
