require_relative '../spec_helper'
require          'logstash/version'

# Test if an installed package can actually be started and runs OK.
RSpec.shared_examples "runnable" do |logstash|

  before(:each) do
    logstash.install({:version => LOGSTASH_VERSION})
  end

  it "is running on #{logstash.hostname}" do
    logstash.start_service
    expect(logstash).to be_running
    logstash.stop_service
  end

end
