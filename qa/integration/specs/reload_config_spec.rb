require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"
require "socket"
require "json"

describe "Test Logstash service when config reload is enabled" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }
  
  let(:timeout_seconds) { 5 }
  let(:initial_port) { random_port }
  let(:reload_port) { random_port }
  let(:retry_attempts) { 10 }
  let(:output_file1) { Stud::Temporary.file.path }
  let(:output_file2) { Stud::Temporary.file.path }
  let(:sample_data) { '74.125.176.147 - - [11/Sep/2014:21:50:37 +0000] "GET /?flav=rss20 HTTP/1.1" 200 29941 "-" "FeedBurner/1.0 (http://www.FeedBurner.com)"' }
  
  let(:initial_config_file) { config_to_temp_file(@fixture.config("initial", { :port => initial_port, :file => output_file1 })) }
  let(:reload_config_file) { config_to_temp_file(@fixture.config("reload", { :port => reload_port, :file => output_file2 })) }

  it "can reload when changes are made to TCP port and grok pattern" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.spawn_logstash("-f", "#{initial_config_file}", "--config.reload.automatic", "true")
    logstash_service.wait_for_logstash
    wait_for_port(initial_port, retry_attempts)
    
    # try sending events with this
    send_data(initial_port, sample_data)
    Stud.try(retry_attempts.times, RSpec::Expectations::ExpectationNotMetError) do
      expect(IO.read(output_file1).gsub("\n", "")).to eq(sample_data)
    end
    
    # check metrics
    result = logstash_service.monitoring_api.event_stats
    expect(result["in"]).to eq(1)
    expect(result["out"]).to eq(1)
    
    # do a reload
    logstash_service.reload_config(initial_config_file, reload_config_file)

    logstash_service.wait_for_logstash
    wait_for_port(reload_port, retry_attempts)
    
    # make sure old socket is closed
    expect(is_port_open?(initial_port)).to be false
    
    send_data(reload_port, sample_data)
    Stud.try(retry_attempts.times, RSpec::Expectations::ExpectationNotMetError) do
      expect(IO.read(output_file2).blank?).to be false
    end
    
    # check metrics. It should be reset
    result = logstash_service.monitoring_api.event_stats
    expect(result["in"]).to eq(1)
    expect(result["out"]).to eq(1)
    
    # check reload stats
    reload_stats = logstash_service.monitoring_api.pipeline_stats["reloads"]
    expect(reload_stats["successes"]).to eq(1)
    expect(reload_stats["failures"]).to eq(0)
    expect(reload_stats["last_success_timestamp"].blank?).to be false
    expect(reload_stats["last_error"]).to eq(nil)
    
    # parse the results and validate
    re = JSON.load(File.new(output_file2))
    expect(re["clientip"]).to eq("74.125.176.147")
    expect(re["response"]).to eq(200)
  end
end