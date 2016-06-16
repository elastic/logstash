# encoding: utf-8
require_relative "../../../spec_helper"
require "logstash/version"
require "fileutils"

shared_examples "logstash install" do |logstash|
  before(:each) do
    logstash.install(LOGSTASH_VERSION)
  end

  after(:each) do
    logstash.uninstall
  end

  describe "on #{logstash.hostname}" do

    describe "plugins as x-packs" do

      let(:pack)        { "https://s3.amazonaws.com/test.elasticsearch.org/logstash/jdbc_pack-#{LOGSTASH_VERSION}.zip" }
      let(:plugin_name) { "logstash-input-jdbc" }

      it "install sucessfully" do
        result = logstash.run_command_in_path("bin/logstash-plugin install #{pack}")
        expect(result).to install_successfully
        expect(result.stdout).to match(/^Validating\s#{pack}\nValidating\s#{plugin_name}\nInstalling\s#{plugin_name}\nInstallation\ssuccessful$/)
      end

      context "when the version does not match" do
        let(:pack)        { "https://s3.amazonaws.com/test.elasticsearch.org/logstash/jdbc_pack-2.0.0.zip" }

        it "fails to install" do
          result = logstash.run_command_in_path("bin/logstash-plugin install #{pack}")
          expect(result).not_to install_successfully
          expect(result.stdout).to match(/^Validating\s#{pack}$/)
          expect(result.stderr).to match(/^ERROR:\sInstallation\saborted,\sverification\sfailed\sfor\s#{pack},\sversion\s2.0.0.$/)
        end
      end

      context "without version" do
        let(:pack)        { "https://s3.amazonaws.com/test.elasticsearch.org/logstash/jdbc_pack.zip" }

        it "fails to install" do
          result = logstash.run_command_in_path("bin/logstash-plugin install #{pack}")
          expect(result).not_to install_successfully
          expect(result.stdout).to match(/^Validating\s#{pack}$/)
          expect(result.stderr).to match(/^ERROR:\sInstallation\saborted,\sverification\sfailed\sfor\s#{pack},\sversion\s.$/)
        end
      end

      context "when the pack does not exist" do
        let(:pack)        { "https://s3.amazonaws.com/test.elasticsearch.org/logstash/foobar-99.0.0.zip" }

        it "fails to install" do
          result = logstash.run_command_in_path("bin/logstash-plugin install #{pack}")
          expect(result).not_to install_successfully
          expect(result.stdout).to match(/^Validating\s#{pack}$/)
          expect(result.stderr).to match(/^ERROR:\sInstallation\saborted,\sverification\sfailed\sfor\s#{pack},\sversion\s99.0.0.$/)
        end
      end
    end

    describe "plugins as gems" do

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

            it "allow to install a specific version" do
              command = logstash.run_command_in_path("bin/logstash-plugin install --version 0.1.0 logstash-filter-qatest")
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

end
