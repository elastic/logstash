# encoding: utf-8
require_relative "../spec_helper"
require_relative "../shared_examples/cli/logstash/version"
require_relative "../shared_examples/cli/logstash-plugin/install"
require_relative "../shared_examples/cli/logstash-plugin/list"
require_relative "../shared_examples/cli/logstash-plugin/uninstall"
require_relative "../shared_examples/cli/logstash-plugin/remove"
require_relative "../shared_examples/cli/logstash-plugin/update"

# This is the collection of test for the CLI interface, this include the plugin manager behaviour, 
# it also include the checks for other CLI options.
describe "CLI operation" do
  config = ServiceTester.configuration
  config.servers.each do |address|
    logstash = ServiceTester::Artifact.new(address, config.lookup[address])
    it_behaves_like "logstash version", logstash
    it_behaves_like "logstash install", logstash
    it_behaves_like "logstash list", logstash
    it_behaves_like "logstash uninstall", logstash
    it_behaves_like "logstash remove", logstash
    it_behaves_like "logstash update", logstash
  end
end
