require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require "stud/try"
require "rspec/wait"

describe "Test Kafka Input" do
  let(:num_retries) { 60 }
  let(:num_events) { 37 }

  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown if @fixture
  }

  it "can ingest 37 apache log lines from Kafka broker" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_background(@fixture.config)

    wait(60).for do
      @fixture.output_exists?
    end.to be true

    wait(60).for do
      File.foreach(@fixture.actual_output).inject(0) {|c, line| c+1}
    end.to eq(num_events)
  end

end
