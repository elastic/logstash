require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"

describe "Test Dead Letter Queue" do

  before(:each) {
    @fixture = Fixture.new(__FILE__)
    IO.write(config_yaml_file, config_yaml)
  }

  after(:each) {
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
  let!(:mp_settings_dir) { Stud::Temporary.directory }
  let!(:config_yaml) { dlq_config.to_yaml }
  let!(:config_yaml_file) { ::File.join(settings_dir, "logstash.yml") }
  let(:generator_config_file) { config_to_temp_file(@fixture.config("root",{ :dlq_dir => dlq_dir })) }

  let!(:pipelines_yaml) { pipelines.to_yaml }
  let!(:pipelines_yaml_file) { ::File.join(settings_dir, "pipelines.yml") }

  it 'can index 1000 documents via dlq - single pipeline' do
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

  let(:pipelines) {[
      {
          "pipeline.id" => "test",
          "pipeline.workers" => 1,
          "dead_letter_queue.enable" => true,
          "pipeline.batch.size" => 1,
          "config.string" => "input { generator { message => '{\"test\":\"one\"}' codec => \"json\" count => 1000 } } filter { mutate { add_field => { \"geoip\" => \"somewhere\" } } } output { elasticsearch {} }"
      },
      {
          "pipeline.id" => "test2",
          "pipeline.workers" => 1,
          "dead_letter_queue.enable" => false,
          "pipeline.batch.size" => 1,
          "config.string" => "input { dead_letter_queue { pipeline_id => 'test' path => \"#{dlq_dir}\" commit_offsets => true } } filter { mutate { remove_field => [\"geoip\"] add_field => {\"mutated\" => \"true\" } } } output { elasticsearch {} }"
      }
  ]}

  let!(:pipelines_yaml) { pipelines.to_yaml }
  let!(:pipelines_yaml_file) { ::File.join(settings_dir, "pipelines.yml") }


  it 'can index 1000 documents via dlq - multi pipeline' do
    IO.write(pipelines_yaml_file, pipelines_yaml)
    logstash_service = @fixture.get_service("logstash")
    logstash_service.spawn_logstash("--path.settings", settings_dir, "--log.level=debug")
    es_service = @fixture.get_service("elasticsearch")
    es_client = es_service.get_client
    # Wait for es client to come up
    sleep(10)
    # test if all data was indexed by ES, but first refresh manually
    es_client.indices.refresh

    logstash_service.wait_for_logstash
    try(50) do
      result = es_client.search(index: 'logstash-*', size: 0, q: '*')
      expect(result["hits"]["total"]).to eq(1000)
    end

    result = es_client.search(index: 'logstash-*', size: 1, q: '*')
    s = result["hits"]["hits"][0]["_source"]
    expect(s["mutated"]).to eq("true")
  end
end
