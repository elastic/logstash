# encoding: utf-8
require_relative '../../framework/fixture'
require_relative '../../framework/settings'
require_relative '../../services/logstash_service'
require_relative '../../framework/helpers'
require "logstash/devutils/rspec/spec_helper"

describe "CLI > logstash-plugin remove" do
  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash_plugin = @fixture.get_service("logstash").plugin_cli
  end

    if RbConfig::CONFIG["host_os"] == "linux"
      context "without internet connection (linux seccomp wrapper)" do

        let(:offline_wrapper_path) { File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "fixtures", "offline_wrapper")) }
        let(:offline_wrapper_cmd) { File.join(offline_wrapper_path, "offline") }

        before do
          Dir.chdir(offline_wrapper_path) do
            system("make clean")
            system("make")
          end
        end

        context "when no other plugins depends on this plugin" do
          it "successfully remove the plugin" do
            execute = @logstash_plugin.run_raw("#{offline_wrapper_cmd} bin/logstash-plugin remove logstash-input-twitter")

            expect(execute.exit_code).to eq(0)
            expect(execute.stderr_and_stdout).to match(/Successfully removed logstash-input-twitter/)

            presence_check = @logstash_plugin.list("logstash-input-twitter")
            expect(presence_check.exit_code).to eq(1)
            expect(presence_check.stderr_and_stdout).to match(/ERROR: No plugins found/)

            @logstash_plugin.install("logstash-input-twitter")
          end
        end

        context "when other plugins depends on this plugin" do
          it "refuses to remove the plugin and display the plugin that depends on it." do
            execute = @logstash_plugin.run_raw("#{offline_wrapper_cmd} bin/logstash-plugin remove logstash-codec-json")

            expect(execute.exit_code).to eq(1)
            expect(execute.stderr_and_stdout).to match(/Failed to remove "logstash-codec-json"/)
            expect(execute.stderr_and_stdout).to match(/logstash-input-beats/) # one of the dependency
            expect(execute.stderr_and_stdout).to match(/logstash-output-udp/) # one of the dependency

            presence_check = @logstash_plugin.list("logstash-codec-json")

            expect(presence_check.exit_code).to eq(0)
            expect(presence_check.stderr_and_stdout).to match(/logstash-codec-json/)
          end
        end

      end
    else
      context "when no other plugins depends on this plugin" do
        it "successfully remove the plugin" do
          execute = @logstash_plugin.remove("logstash-input-twitter")

          expect(execute.exit_code).to eq(0)
          expect(execute.stderr_and_stdout).to match(/Successfully removed logstash-input-twitter/)

          presence_check = @logstash_plugin.list("logstash-input-twitter")
          expect(presence_check.exit_code).to eq(1)
          expect(presence_check.stderr_and_stdout).to match(/ERROR: No plugins found/)

          @logstash_plugin.install("logstash-input-twitter")
        end
      end

      context "when other plugins depends on this plugin" do
        it "refuses to remove the plugin and display the plugin that depends on it." do
          execute = @logstash_plugin.remove("logstash-codec-json")

          expect(execute.exit_code).to eq(1)
          expect(execute.stderr_and_stdout).to match(/Failed to remove "logstash-codec-json"/)
          expect(execute.stderr_and_stdout).to match(/logstash-input-beats/) # one of the dependency
          expect(execute.stderr_and_stdout).to match(/logstash-output-udp/) # one of the dependency

          presence_check = @logstash_plugin.list("logstash-codec-json")

          expect(presence_check.exit_code).to eq(0)
          expect(presence_check.stderr_and_stdout).to match(/logstash-codec-json/)
        end
      end
    end
end
