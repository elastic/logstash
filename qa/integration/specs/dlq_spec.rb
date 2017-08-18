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
    begin
      es_client = @fixture.get_service("elasticsearch").get_client
      es_client.indices.delete(index: 'logstash-*') unless es_client.nil?
    ensure
      @fixture.teardown
    end
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
  let(:generator_config_file) { config_to_temp_file(@fixture.config("root",{ :dlq_dir => dlq_dir })) }


  before(:each) do
    IO.write(config_yaml_file, config_yaml)
  end

  it 'can index 1000 generated documents' do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_background_with_config_settings(generator_config_file, settings_dir)
    es_service = @fixture.get_service("elasticsearch")
    es_client = es_service.get_client
    # Wait for es client to come up
    sleep(10)
    # now we test if all data was indexed by ES, but first refresh manually
    es_client.indices.refresh

    logstash_service.wait_for_logstash
    try(50) do
      result = es_client.search(index: 'logstash-*', size: 0, q: '*')
      expect(result["hits"]["total"]).to eq(1000)
    end

    # randomly checked for results and structured fields
    result = es_client.search(index: 'logstash-*', size: 1, q: '*')
    s = result["hits"]["hits"][0]["_source"]
    expect(s["mutated"]).to eq("true")
  end
end
