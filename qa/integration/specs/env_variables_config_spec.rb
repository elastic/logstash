require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"

describe "Test Logstash configuration" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }
  
  let(:retry_attempts) { 10 }
  let(:test_tcp_port) { "9999" }
  let(:test_tag) { "environment_variables_are_evil" }
  let(:test_path) { Stud::Temporary.directory }
  let(:sample_data) { '74.125.176.147 - - [11/Sep/2014:21:50:37 +0000] "GET /?flav=rss20 HTTP/1.1" 200 29941 "-" "FeedBurner/1.0 (http://www.FeedBurner.com)"' }

  it "expands environment variables in all plugin blocks" do
    # set ENV variables before starting the service
    test_env = {}
    test_env["TEST_ENV_TCP_PORT"] = test_tcp_port
    test_env["TEST_ENV_TAG"] = test_tag
    test_env["TEST_ENV_PATH"] = test_path
    
    logstash_service = @fixture.get_service("logstash")
    logstash_service.env_variables = test_env
    logstash_service.start_background(@fixture.config)
    # check if TCP port env variable was resolved
    Stud.try(retry_attempts.times, RSpec::Expectations::ExpectationNotMetError) do
      expect(is_port_open?(test_tcp_port)).to be true
    end
    
    #send data and make sure all env variables are expanded by checking each stage
    send_data(test_tcp_port, sample_data)
    output_file = File.join(test_path, "logstash_env_test.log")
    Stud.try(retry_attempts.times, RSpec::Expectations::ExpectationNotMetError) do
      expect(File.exists?(output_file)).to be true
    end
    # should have created the file using env variable with filters adding a tag based on env variable
    Stud.try(retry_attempts.times, RSpec::Expectations::ExpectationNotMetError) do
      expect(IO.read(output_file).gsub("\n", "")).to eq("#{sample_data} blah,environment_variables_are_evil")
    end
  end
end  