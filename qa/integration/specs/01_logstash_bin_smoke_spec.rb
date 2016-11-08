require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"
require "yaml"
require 'json'
require 'open-uri'

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
  let(:port1) { random_port }
  let(:port2) { random_port }
  let(:config3) { config_to_temp_file(@fixture.config("root", { :port => port2 })) }

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

  it "should still merge when -e is specified and -f has no valid config files" do
    config_string = "input { tcp { port => #{port1} } }"
    @ls1.spawn_logstash("-e", config_string, "-f" "/tmp/foobartest")
    @ls1.wait_for_logstash

    try(20) do
      expect(is_port_open?(port1)).to be true
    end
  end

  it "should not start when -e is not specified and -f has no valid config files" do
    @ls1.spawn_logstash("-e", "", "-f" "/tmp/foobartest")
    expect(is_port_open?(9600)).to be false
  end

  it "should merge config_string when both -f and -e is specified" do
    config_string = "input { tcp { port => #{port1} } }"
    @ls1.spawn_logstash("-e", config_string, "-f", config3)
    @ls1.wait_for_logstash

    # Both ports should be reachable
    try(20) do
      expect(is_port_open?(port1)).to be true
    end

    try(20) do
      expect(is_port_open?(port2)).to be true
    end
  end

  def get_id
    JSON.parse(open("http://localhost:9600/").read)["id"]
  end

  it "should keep the same id between restarts" do
    config_string = "input { tcp { port => #{port1} } }"

    start_ls = lambda {
      @ls1.spawn_logstash("-e", config_string, "-f", config3)
      @ls1.wait_for_logstash
    }
    start_ls.call()
    first_id = get_id
    @ls1.teardown
    start_ls.call()
    second_id = get_id
    expect(first_id).to eq(second_id)
  end
end
