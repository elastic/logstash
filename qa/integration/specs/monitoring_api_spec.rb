require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require "logstash/devutils/rspec/spec_helper"

describe "Monitoring API", :integration => true do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }

  it "can retrieve event stats" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    5.times { logstash_service.write_to_stdin("Hello world") }
    # check metrics
    result = logstash_service.monitoring_api.event_stats
    try { expect(result["in"]).to eq(5) }
    expect(result["in"]).to eq(5)
  end

end
