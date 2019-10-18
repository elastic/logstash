# encoding: utf-8
require_relative "../../../spec_helper"
require "logstash/version"
require "fileutils"

shared_examples "logstash list" do |logstash|
  describe "logstash-plugin list on #{logstash.hostname}" do
    before(:all) do
      logstash.install({:version => LOGSTASH_VERSION})
    end

    after(:all) do
      logstash.uninstall
    end

    let(:plugin_name) { /logstash-(?<type>\w+)-(?<name>\w+)/ }
    let(:plugin_name_with_version) { /#{plugin_name}\s\(\d+\.\d+.\d+(.\w+)?\)/ }

    context "without a specific plugin" do
      it "display a list of plugins" do
        result = logstash.run_command_in_path("bin/logstash-plugin list")
        expect(result.stdout.split("\n").size).to be > 1
      end

      it "display a list of installed plugins" do
        result = logstash.run_command_in_path("bin/logstash-plugin list --installed")
        expect(result.stdout.split("\n").size).to be > 1
      end

      it "list the plugins with their versions" do
        result = logstash.run_command_in_path("bin/logstash-plugin list --verbose")

        stdout = StringIO.new(result.stdout)
        while line = stdout.gets
          expect(line).to match(/^#{plugin_name_with_version}$/)

          # Integration Plugins list their sub-plugins, e.g.,
          # ~~~
          # logstash-integration-kafka (10.0.0)
          # ├── logstash-input-kafka
          # └── logstash-output-kafka
          # ~~~
          if Regexp.last_match[:type] == 'integration'
            while line = stdout.gets
              expect(line).to match(/^(?: [├└]── )#{plugin_name}$/)
              break if line.start_with?(' └')
            end
          end
        end
      end
    end

    context "with a specific plugin" do
      let(:plugin_name) { "logstash-input-stdin" }
      it "list the plugin and display the plugin name" do
        result = logstash.run_command_in_path("bin/logstash-plugin list #{plugin_name}")
        expect(result).to run_successfully_and_output(/^#{plugin_name}$/)
      end

      it "list the plugin with his version" do
        result = logstash.run_command_in_path("bin/logstash-plugin list --verbose #{plugin_name}")
        expect(result).to run_successfully_and_output(/^#{plugin_name} \(\d+\.\d+.\d+\)/)
      end
    end
  end
end
