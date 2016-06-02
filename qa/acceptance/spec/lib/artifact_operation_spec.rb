# encoding: utf-8
require_relative '../spec_helper'
require_relative '../shared_examples/installed'
require_relative '../shared_examples/running'
require_relative '../shared_examples/updated'

# This tests verify that the generated artifacts could be used properly in a relase, implements https://github.com/elastic/logstash/issues/5070
describe "artifacts operation" do
  config = ServiceTester.configuration
  config.servers.each do |address|
    logstash = ServiceTester::Artifact.new(address, config.lookup[address])
    it_behaves_like "installable", logstash
    it_behaves_like "updated", logstash
  end
end
