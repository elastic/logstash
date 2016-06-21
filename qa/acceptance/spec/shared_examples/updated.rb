require_relative '../spec_helper'
require          'logstash/version'

# This test checks if the current package could used to update from the latest version released.
RSpec.shared_examples "updated" do |logstash|

  before(:all) { logstash.uninstall }
  after(:all)  do
    logstash.stop_service # make sure the service is stopped
    logstash.uninstall #remove the package to keep uniform state
  end

  before(:each) do
    options={:version => LOGSTASH_LATEST_VERSION, :snapshot => false, :base => "./" }
    logstash.install(options) # make sure latest version is installed
  end

  it "can be updated an run on #{logstash.hostname}" do
    expect(logstash).to be_installed
    # Performing the update
    logstash.install({:version => LOGSTASH_VERSION})
    expect(logstash).to be_installed
    # starts the service to be sure it runs after the upgrade
    logstash.start_service
    expect(logstash).to be_running
  end
end
