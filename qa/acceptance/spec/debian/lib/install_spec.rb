# encoding: utf-8
require_relative "../spec_helper"
require "logstash/version"

describe "artifacts", :platform => :debian do

  shared_examples "installable" do |host, name|

    before(:each) do
      install("/logstash-build/logstash-#{LOGSTASH_VERSION}_all.deb", host)
    end

    it "is installed on #{name}" do
      expect("logstash").to be_installed.on(host)
    end

    it "is running on #{name}" do
      start_service("logstash", host)
      expect("logstash").to be_running.on(host)
      stop_service("logstash", host)
    end

    it "is removable on #{name}" do
      uninstall("logstash", host)
      expect("logstash").to be_removed.on(host)
    end
  end

  config = ServiceTester.configuration
  config.servers.each do |host|
    it_behaves_like "installable", host, config.lookup[host]
  end
end
