# encoding: utf-8
require_relative "../../../spec_helper"
require "logstash/version"
require "fileutils"

shared_examples "integration plugins compatible" do |logstash|
  describe "logstash-plugin install on #{logstash.hostname}" do
    let(:plugin) { "logstash-integration-rabbitmq" }
    before :each do
      logstash.install({:version => LOGSTASH_VERSION})
    end

    after :each do
      logstash.uninstall
    end

    context "when the integration is installed" do
      before(:each) do
        logstash.run_command_in_path("bin/logstash-plugin install logstash-integration-rabbitmq")
      end
      context "trying to install an inner plugin separately" do
        it "fails to install" do
          result = logstash.run_command_in_path("bin/logstash-plugin install logstash-input-rabbitmq")
          expect(result.stderr).to match(/is already provided by/)
        end
      end
    end
    context "when the integration is not installed" do
      context "if an inner plugin is installed" do
        before(:each) do
          logstash.run_command_in_path("bin/logstash-plugin install logstash-input-rabbitmq")
        end
        it "installing the integrations uninstalls the inner plugin" do
          logstash.run_command_in_path("bin/logstash-plugin install logstash-integration-rabbitmq")
          result = logstash.run_command_in_path("bin/logstash-plugin list logstash-input-rabbitmq")
          expect(result.stdout).to_not match(/^logstash-input-rabbitmq/)
        end
      end
    end
  end

  describe "logstash-plugin uninstall on #{logstash.hostname}" do
    let(:plugin) { "logstash-integration-rabbitmq" }
    before :each do
      logstash.install({:version => LOGSTASH_VERSION})
    end

    after :each do
      logstash.uninstall
    end

    context "when the integration is installed" do
      before(:each) do
        logstash.run_command_in_path("bin/logstash-plugin install logstash-integration-rabbitmq")
      end
      context "trying to uninstall an inner plugin" do
        it "fails to uninstall it" do
          result = logstash.run_command_in_path("bin/logstash-plugin uninstall logstash-input-rabbitmq")
          expect(result.stderr).to match(/is already provided by/)
        end
      end
    end
  end

  describe "logstash-plugin list on #{logstash.hostname}" do
    let(:plugin) { "logstash-integration-rabbitmq" }
    before :each do
      logstash.install({:version => LOGSTASH_VERSION})
    end

    after :each do
      logstash.uninstall
    end

    context "when the integration is installed" do
      before(:each) do
        logstash.run_command_in_path("bin/logstash-plugin install logstash-integration-rabbitmq")
      end
      context "listing an integration" do
        let(:result) { logstash.run_command_in_path("bin/logstash-plugin list logstash-integration-rabbitmq") }
        it "shows its inner plugin" do
          expect(result.stdout).to match(/logstash-input-rabbitmq/m)
        end
      end
      context "listing an inner plugin" do
        let(:result) { logstash.run_command_in_path("bin/logstash-plugin list logstash-input-rabbitmq") }
        it "matches the integration that contains it" do
          expect(result.stdout).to match(/logstash-integration-rabbitmq/m)
        end
      end
    end
  end
end
