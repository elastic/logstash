# encoding: utf-8
require_relative "../../../spec_helper"
require "logstash/version"
require "fileutils"

shared_examples "logstash generate" do |logstash|
  before(:each) do
    logstash.install({:version => LOGSTASH_VERSION})
  end

  after(:each) do
    logstash.uninstall
  end

  describe "on #{logstash.hostname}" do

    GENERATE_TYPES = ["input", "filter", "codec", "output"]
    GENERATE_TYPES.each do |type|
      context "with type #{type}" do
        it "successfully generate the plugin skeleton" do
          command = logstash.run_command_in_path("bin/logstash-plugin generate --type #{type} --name qatest-generated")
          expect(logstash).to File.directory?("logstash-#{type}-qatest-generated")
        end
        it "successfully install the plugin" do
            command = logstash.run_command_in_path("bin/logstash-plugin install logstash-#{type}-qatest-generated")
            expect(command).to install_successfully
            expect(logstash).to have_installed?("logstash-#{type}-qatest-generated")
        end
      end
    end
  end
end
