require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../framework/helpers'
require "stud/temporary"
require "stud/try"
require "rspec/wait"
require "yaml"
require "fileutils"

describe "Java plugin API" do
  before(:all) do
    @fixture = Fixture.new(__FILE__)
  end

  before(:each) {
    @logstash = @fixture.get_service("logstash")
  }

  after(:all) {
    @fixture.teardown
  }

  after(:each) {
    @logstash.teardown
  }

  let(:max_retry) { 120 }
  let!(:settings_dir) { Stud::Temporary.directory }

  it "successfully sends events through Java plugins" do

    @logstash.start_background_with_config_settings(config_to_temp_file(@fixture.config), settings_dir)

    # wait for Logstash to start
    started = false
    while !started
      begin
        sleep(1)
        result = @logstash.monitoring_api.event_stats
        started = !result.nil?
      rescue
        retry
      end
    end

    Stud.try(max_retry.times, RSpec::Expectations::ExpectationNotMetError) do
      result = @logstash.monitoring_api.event_stats
      expect(result["in"]).to eq(1)
    end
  end
end
