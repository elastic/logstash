# encoding: utf-8
require_relative "../../../spec_helper"
require "logstash/version"
require "fileutils"

shared_examples "logstash install" do |logstash|
  before(:each) do
    logstash.install({:version => LOGSTASH_VERSION})
  end

  after(:each) do
    logstash.uninstall
  end

  describe "on #{logstash.hostname}" do
    context "with a direct internet connection" do
      context "when the plugin exist" do
        context "from a local `.GEM` file" do
          let(:gem_name) { "logstash-filter-qatest-0.1.1.gem" }
          let(:gem_path_on_vagrant) { "/tmp/#{gem_name}" }
          before(:each) do
            logstash.download("https://rubygems.org/gems/#{gem_name}", gem_path_on_vagrant)
          end

          after(:each) { logstash.delete_file(gem_path_on_vagrant) }

          it "successfully install the plugin" do
            command = logstash.run_command_in_path("bin/logstash-plugin install #{gem_path_on_vagrant}")
            expect(command).to install_successfully
            expect(logstash).to have_installed?("logstash-filter-dns")
          end
        end

        context "when fetching a gem from rubygems" do

          it "successfully install the plugin" do
            command = logstash.run_command_in_path("bin/logstash-plugin install logstash-filter-qatest")
            expect(command).to install_successfully
            expect(logstash).to have_installed?("logstash-filter-qatest")
          end

          it "successfully install the plugin when verification is disabled" do
            command = logstash.run_command_in_path("bin/logstash-plugin install --no-verify logstash-filter-qatest")
            expect(command).to install_successfully
            expect(logstash).to have_installed?("logstash-filter-qatest")
          end

          it "fails when installing a non logstash plugin" do
            command = logstash.run_command_in_path("bin/logstash-plugin install  bundler")
            expect(command).not_to install_successfully
          end

          it "allow to install a specific version" do
            command = logstash.run_command_in_path("bin/logstash-plugin install --no-verify --version 0.1.0 logstash-filter-qatest")
            expect(command).to install_successfully
            expect(logstash).to have_installed?("logstash-filter-qatest", "0.1.0")
          end
        end
      end

      context "when the plugin doesnt exist" do
        it "fails to install and report an error" do
          command = logstash.run_command_in_path("bin/logstash-plugin install --no-verify logstash-output-impossible-plugin")
          expect(command.stderr).to match(/Plugin not found, aborting/)
        end
      end
    end
  end
end
