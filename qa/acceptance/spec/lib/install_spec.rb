# encoding: utf-8
require_relative '../spec_helper'
require_relative '../shared_examples/installed'

describe "artifacts" do
  config = ServiceTester.configuration
  config.servers.each do |host|
    it_behaves_like "installable", host, config.lookup[host]
  end
end
