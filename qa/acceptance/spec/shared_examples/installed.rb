require_relative '../spec_helper'
require          'logstash/version'

# This test checks if a package is possible to be installed without errors.
RSpec.shared_examples "installable" do |logstash|

  before(:each) do
    logstash.uninstall
    logstash.install({:version => LOGSTASH_VERSION})
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
