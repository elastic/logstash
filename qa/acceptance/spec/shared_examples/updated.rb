require_relative '../spec_helper'
require          'logstash/version'

RSpec.shared_examples "updated" do |logstash|

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
