# encoding: utf-8
require_relative '../spec_helper'
require_relative '../shared_examples/installed'
require_relative '../shared_examples/running'
require_relative '../shared_examples/updated'

describe "artifacts operation" do
  config = ServiceTester.configuration

  config.servers.each do |address|
    logstash = ServiceTester::Artifact.new(address, config.lookup[address])

    describe "installation" do
      before(:each) do
        logstash.install(LOGSTASH_VERSION)
      end

      it "is installed on #{logstash.hostname}" do
        expect(logstash).to be_installed
      end

      it "is running on #{logstash.hostname}" do
        logstash.start_service
        expect(logstash).to be_running
        logstash.stop_service
      end

      it "is removable on #{logstash.hostname}" do
        logstash.uninstall
        expect(logstash).to be_removed
      end
    end
  end

  config.servers.each do |address|
    logstash = ServiceTester::Artifact.new(address, config.lookup[address])

    describe "update" do
      before (:all) { logstash.snapshot }
      after  (:all) { logstash.restore }

      it "can update on #{logstash.hostname}" do
        logstash.install(LOGSTASH_LATEST_VERSION, "./")
        expect(logstash).to be_installed
        logstash.install(LOGSTASH_VERSION)
        expect(logstash).to be_installed
      end

      it "can run on #{logstash.hostname}" do
        logstash.start_service
        expect(logstash).to be_running
        logstash.stop_service
      end
    end
  end
end
