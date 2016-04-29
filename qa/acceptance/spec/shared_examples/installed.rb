require_relative '../spec_helper'
require          'logstash/version'

RSpec.shared_examples "installable" do |logstash|

  before(:each) do
    logstash.install(LOGSTASH_VERSION)
  end

  it "is installed on #{logstash.host}" do
    expect(logstash).to be_installed
  end

  it "is running on #{logstash.host}" do
    logstash.start_service
    expect(logstash).to be_running
    logstash.stop_service
  end

  it "is removable on #{logstash.host}" do
    logstash.uninstall
    expect(logstash).to be_removed
  end
end
