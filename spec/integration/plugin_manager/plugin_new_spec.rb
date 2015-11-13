# Encoding: utf-8
require_relative "../spec_helper"
require "fileutils"

describe "bin/logstash-plugin generate" do

  shared_examples "bin/logstash-plugin generate" do
    let(:plugin_name)      { "dummy" }
    let(:full_plugin_name) { "logstash-#{plugin_type}-#{plugin_name}" }

    describe "plugin creation" do

      before(:each) do
        FileUtils.rm_rf(full_plugin_name)
      end

      after(:each) do
        FileUtils.rm_rf(full_plugin_name)
      end

      it "generate a new plugin" do
        result = command("bin/logstash-plugin generate --type #{plugin_type} --name #{plugin_name}")
        expect(result.exit_status).to eq(0)
        expect(result.stdout).to match(/Creating #{full_plugin_name}/)
        expect(Dir.exist?("#{full_plugin_name}")).to eq(true)
      end

      it "raise an error if the plugin is already generated" do
        command("bin/logstash-plugin generate --type #{plugin_type} --name #{plugin_name}")
        result = command("bin/logstsh-plugin generate --type #{plugin_type} --name #{plugin_name}")
        expect(result.exit_status).to eq(1)
      end
    end
  end

  describe "bin/logstash-plugin generate input" do
    it_behaves_like "bin/logstash-plugin generate" do
      let(:plugin_type) { "input" }
    end
  end

  describe "bin/logstash-plugin generate filter" do
    it_behaves_like "bin/logstash-plugin generate" do
      let(:plugin_type) { "filter" }
    end
  end

  describe "bin/logstash-plugin generate output" do
    it_behaves_like "bin/logstash-plugin generate" do
      let(:plugin_type) { "output" }
    end
  end
end
