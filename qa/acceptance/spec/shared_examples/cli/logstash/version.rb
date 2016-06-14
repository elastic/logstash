# encoding: utf-8
require_relative "../../../spec_helper"
require "logstash/version"

shared_examples "logstash version" do |logstash|
  describe "logstash --version" do
    before :all do
      logstash.install({:version => LOGSTASH_VERSION})
    end

    after :all do
      logstash.uninstall
    end

    context "on #{logstash.hostname}" do
      it "returns the right logstash version" do
        result = logstash.run_command_in_path("bin/logstash --version")
        expect(result).to run_successfully_and_output(/#{LOGSTASH_VERSION}/)
      end
      context "when also using the --path.settings argument" do
        it "returns the right logstash version" do
          result = logstash.run_command_in_path("bin/logstash --path.settings=/etc/logstash --version")
          expect(result).to run_successfully_and_output(/#{LOGSTASH_VERSION}/)
        end
      end
    end
  end
end
