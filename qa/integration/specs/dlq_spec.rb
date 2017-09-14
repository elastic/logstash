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
      @fixture.teardown
  }

  before(:each) {
    IO.write(config_yaml_file, config_yaml)
  }

  after(:each) do
    es_client = @fixture.get_service("elasticsearch").get_client
    es_client.indices.delete(index: 'logstash-*') unless es_client.nil?
    logstash_service.teardown
  end

  let(:logstash_service) { @fixture.get_service("logstash") }
  let(:dlq_dir) { Stud::Temporary.directory }
  let(:dlq_config) {
      {
          "dead_letter_queue.enable" => true,
          "path.dead_letter_queue" => dlq_dir,
          "log.level" => "debug"
      }
  }
  let!(:config_yaml) { dlq_config.to_yaml }
  let!(:config_yaml_file) { ::File.join(settings_dir, "logstash.yml") }

  let!(:settings_dir) { Stud::Temporary.directory }

  shared_examples_for "it can send 1000 documents to and index from the dlq" do
    it 'should index all documents' do
      es_service = @fixture.get_service("elasticsearch")
      es_client = es_service.get_client
      # test if all data was indexed by ES, but first refresh manually
      es_client.indices.refresh

      logstash_service.wait_for_logstash
      try(60) do
        begin
          result = es_client.search(index: 'logstash-*', size: 0, q: '*')
          hits = result["hits"]["total"]
        rescue Elasticsearch::Transport::Transport::Errors::ServiceUnavailable => e
          puts "Elasticsearch unavailable #{e.inspect}"
          hits = 0
        end
        expect(hits).to eq(1000)
      end

      result = es_client.search(index: 'logstash-*', size: 1, q: '*')
      s = result["hits"]["hits"][0]["_source"]
      expect(s["mutated"]).to eq("true")
    end
  end

  context 'using pipelines.yml' do
    let!(:pipelines_yaml) { pipelines.to_yaml }
    let!(:pipelines_yaml_file) { ::File.join(settings_dir, "pipelines.yml") }

    before :each do
      IO.write(pipelines_yaml_file, pipelines_yaml)
      logstash_service.spawn_logstash("--path.settings", settings_dir, "--log.level=debug")
    end

    context 'with multiple pipelines' do
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

      it_behaves_like 'it can send 1000 documents to and index from the dlq'
    end

    context 'with a single pipeline' do
      let(:pipelines) {[
        {
            "pipeline.id" => "main",
            "pipeline.workers" => 1,
            "dead_letter_queue.enable" => true,
            "pipeline.batch.size" => 1,
            "config.string" => "
                input { generator{ message => '{\"test\":\"one\"}' codec => \"json\" count => 1000 }
                        dead_letter_queue { path => \"#{dlq_dir}\" commit_offsets => true }
                }
                filter {
                  if ([geoip]) { mutate { remove_field => [\"geoip\"] add_field => { \"mutated\" => \"true\" } } }
                  else{ mutate { add_field => { \"geoip\" => \"somewhere\" } } }
                }
                output { elasticsearch {} }"
        }
      ]}

      it_behaves_like 'it can send 1000 documents to and index from the dlq'
    end
  end

  context 'using logstash.yml and separate config file' do
    let(:generator_config_file) { config_to_temp_file(@fixture.config("root",{ :dlq_dir => dlq_dir })) }

    before :each do
      logstash_service.start_background_with_config_settings(generator_config_file, settings_dir)
    end
    it_behaves_like 'it can send 1000 documents to and index from the dlq'
  end
end
