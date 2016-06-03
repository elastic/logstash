# encoding: utf-8
require_relative '../spec_helper'
require_relative '../shared_examples/installed'
require_relative '../shared_examples/running'
require_relative '../shared_examples/updated'

describe "artifacts operation" do
  config = ServiceTester.configuration
  config.servers.each do |address|
    logstash = ServiceTester::Artifact.new(address, config.lookup[address])
    it_behaves_like "installable", logstash
    it_behaves_like "updated", logstash
  end
end
