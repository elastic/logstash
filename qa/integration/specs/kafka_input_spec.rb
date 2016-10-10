require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require "rspec/wait"

describe "Test Kafka Input" do
  let(:timeout_seconds) { 30 }
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }

  it "can ingest 37 apache log lines from Kafka broker" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_background(@fixture.config)

    wait(timeout_seconds).for { @fixture.output_exists? }.to be true
    expect(@fixture.output_equals_expected?).to be true
      lambda { "Expected File output to match what was ingested into Kafka." }
  end

end
