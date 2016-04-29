require_relative '../spec_helper'
require          'logstash/version'

RSpec.shared_examples "runnable" do |logstash|

  before(:each) do
    logstash.install(LOGSTASH_VERSION)
  end

  it "is running on #{logstash.host}" do
    logstash.start_service
    expect(logstash).to be_running
    logstash.stop_service
  end

end
