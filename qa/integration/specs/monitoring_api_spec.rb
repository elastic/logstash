require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require "logstash/devutils/rspec/spec_helper"

describe "Test Monitoring API" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }
  
  after(:each) {
    @fixture.get_service("logstash").teardown
  }
  
  let(:number_of_events) { 5 }
  let(:max_retry) { 120 }

  it "can retrieve event stats" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    number_of_events.times { logstash_service.write_to_stdin("Hello world") }

    begin
      sleep(1) while (result = logstash_service.monitoring_api.event_stats).nil?
    rescue
      retry
    end

    Stud.try(max_retry.times, RSpec::Expectations::ExpectationNotMetError) do
       result = logstash_service.monitoring_api.event_stats
       expect(result["in"]).to eq(number_of_events)
    end
  end

  it "can retrieve JVM stats" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash

    Stud.try(max_retry.times, RSpec::Expectations::ExpectationNotMetError) do
       result = logstash_service.monitoring_api.node_stats
       expect(result["jvm"]["uptime_in_millis"]).to be > 100
    end
  end

end
