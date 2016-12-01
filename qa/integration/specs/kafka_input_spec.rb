require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require "rspec/wait"
require "logstash/devutils/rspec/spec_helper"

describe "Test Kafka Input" do
  let(:num_retries) { 60 }
  let(:num_events) { 37 }

  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }

  it "can ingest 37 apache log lines from Kafka broker" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_background(@fixture.config)

    try(num_retries) do
      expect(@fixture.output_exists?).to be true
    end

    try(num_retries) do
      count = File.foreach(@fixture.actual_output).inject(0) {|c, line| c+1}
      expect(count).to eq(num_events)
    end
  end

end
