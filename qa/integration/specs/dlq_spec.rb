require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"

describe "Test Dead Letter Queue" do

  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    es_client = @fixture.get_service("elasticsearch").get_client
    es_client.indices.delete(index: 'logstash-*')
    @fixture.teardown
  }

  let(:dlq_dir) { Stud::Temporary.directory }

  let(:dlq_config) {
      {
          "dead_letter_queue.enable" => true,
          "path.dead_letter_queue" => dlq_dir,
          "log.level" => "debug"
      }
  }

  let!(:settings_dir) { Stud::Temporary.directory }
  let!(:config_yaml) { dlq_config.to_yaml }
  let!(:config_yaml_file) { ::File.join(settings_dir, "logstash.yml") }
  let(:initial_config_file) { config_to_temp_file(@fixture.config("root",{ :dlq_dir => dlq_dir })) }


  before(:each) do
    IO.write(config_yaml_file, config_yaml)
  end

  it "can ingest 37 log lines of sample apache logs" do
    logstash_service = @fixture.get_service("logstash")

    logstash_service.start_with_config_file_string_settings(initial_config_file, settings_dir)
    es_service = @fixture.get_service("elasticsearch")

    es_client = es_service.get_client
    # now we test if all data was indexed by ES, but first refresh manually
    es_client.indices.refresh
    puts "Waiting for logstash"
    logstash_service.wait_for_logstash
    puts "Logstash id ready"
    logstash_service.write_to_stdin(IO.read(@fixture.input))
    puts "Wrote to stdin"
    started = false

    try(100) do
      result = es_client.search(index: 'logstash-*', size: 0, q: '*')
      puts "Logstash Service alive - #{logstash_service.is_port_open?}"
      if logstash_service.is_port_open?
        started = true
      end
      if started && !logstash_service.is_port_open?
        raise "Logstash Service has stopped"
      end
      expect(result["hits"]["total"]).to eq(37)
    end

    # randomly checked for results and structured fields
    result = es_client.search(index: 'logstash-*', size: 1, q: 'dynamic')
    s = result["hits"]["hits"][0]["_source"]
    expect(s["bytes"]).to eq(18848)
    expect(s["response"]).to eq(200)
    expect(s["clientip"]).to eq("213.113.233.227")
    expect(s["geoip"]).to be_nil
    expect(s["verb"]).to eq("GET")
    expect(s["mutated"]).to eq("true")
  end
end
