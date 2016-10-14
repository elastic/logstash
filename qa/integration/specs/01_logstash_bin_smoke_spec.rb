require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"
require "yaml"

describe "Test Logstash instance" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
    # used in multiple LS tests
    @ls1 = @fixture.get_service("logstash")
    @ls2 = LogstashService.new(@fixture.settings)
  }

  after(:all) {
    @fixture.teardown
  }
  
  after(:each) {
    @ls1.teardown
    @ls2.teardown
  }
  
  let(:num_retries) { 10 }
  let(:config1) { config_to_temp_file(@fixture.config("root", { :port => random_port })) }
  let(:config2) { config_to_temp_file(@fixture.config("root", { :port => random_port })) }

  it "can start the embedded http server on default port 9600" do
    @ls1.start_with_stdin
    try(num_retries) do
      expect(is_port_open?(9600)).to be true
    end
  end
  
  it "multiple of them can be started on the same box with automatically trying different ports for HTTP server" do
    @ls1.spawn_logstash("-f", config1)
    try(num_retries) do
      expect(is_port_open?(9600)).to be true
    end

    puts "will try to start the second LS instance on 9601"

    # bring up new LS instance
    @ls2.spawn_logstash("-f", config2)
    try(20) do
      expect(is_port_open?(9601)).to be true
    end

    expect(@ls1.process_id).not_to eq(@ls2.process_id)
  end
  
  it "gets the right version when asked" do
    expected = YAML.load_file(LogstashService::LS_VERSION_FILE)
    expect(@ls1.get_version.strip).to eq("logstash #{expected['logstash']}")
  end
end    