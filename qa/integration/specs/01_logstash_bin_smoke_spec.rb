require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"
require "yaml"

describe "Test Logstash instance" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }
  
  let(:retry_attempts) { 10 }
  let(:config1) { config_to_temp_file(@fixture.config("root", { :port => '9980' })) }
  let(:config2) { config_to_temp_file(@fixture.config("root", { :port => '9981' })) }

  it "can start the embedded http server on default port 9600" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    Stud.try(retry_attempts.times, RSpec::Expectations::ExpectationNotMetError) do
      expect(is_port_open?(9600)).to be true
    end
    logstash_service.teardown
  end
  
  it "multiple of them can be started on the same box with automatically trying different ports for HTTP server" do
    ls1 = @fixture.get_service("logstash")
    ls1.spawn_logstash("-f", config1)
    Stud.try(retry_attempts.times, RSpec::Expectations::ExpectationNotMetError) do
      expect(is_port_open?(9600)).to be true
    end

    # bring up new LS instance
    ls2 = LogstashService.new(@fixture.settings)
    ls2.spawn_logstash("-f", config2)
    Stud.try(retry_attempts.times, RSpec::Expectations::ExpectationNotMetError) do
      expect(is_port_open?(9601)).to be true
    end

    expect(ls1.process_id).not_to eq(ls2.process_id)
  end
  
  it "gets the right version when asked" do
    ls = @fixture.get_service("logstash")
    expected = YAML.load_file(LogstashService::LS_VERSION_FILE)
    expect(ls.get_version.strip).to eq("logstash #{expected['logstash']}")
  end
  
  

end    