# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require_relative 'spec_helper.rb'

require "logstash/devutils/rspec/spec_helper"

describe "Test Dead Letter Queue" do
  # template with an ip field
  let(:template) { serverless? ? { "index_patterns": ["te*"], "template": {"mappings": { "properties": { "ip": { "type": "ip" }}}} } :
                     { "index_patterns": ["te*"], "mappings": { "properties": { "ip": { "type": "ip" }}}} }
  let(:template_api) { serverless? ? "_index_template" : "_template" }
  # a message that is incompatible with the template
  let(:message) { {"message": "hello", "ip": 1}.to_json }

  before(:all) {
    @fixture = Fixture.new(__FILE__)
    es_allow_wildcard_deletes(@fixture.get_service("elasticsearch").get_client)
  }

  after(:all) {
    clean_es(@fixture.get_service("elasticsearch").get_client)
    @fixture.teardown
  }

  before(:each) {
    IO.write(config_yaml_file, config_yaml)
    es_client = @fixture.get_service("elasticsearch").get_client
    clean_es(es_client)
    es_client.perform_request("PUT", "#{template_api}/ip-template", {}, template)
  }

  after(:each) do
    logstash_service.teardown
  end

  let(:logstash_service) { @fixture.get_service("logstash") }
  let(:dlq_dir) { Stud::Temporary.directory }
  let(:dlq_config) {
      {
          "dead_letter_queue.enable" => true,
          "path.dead_letter_queue" => dlq_dir,
      }
  }
  let!(:config_yaml) { dlq_config.to_yaml }
  let!(:config_yaml_file) { ::File.join(settings_dir, "logstash.yml") }

  let!(:settings_dir) { Stud::Temporary.directory }
  let(:serverless_es_config) do
    if serverless?
      " hosts => '${ES_ENDPOINT}' api_key => '${PLUGIN_API_KEY}'"
    else
      ""
    end
  end

  shared_examples_for "it can send 1000 documents to and index from the dlq" do
    it 'should index all documents' do
      es_service = @fixture.get_service("elasticsearch")
      es_client = es_service.get_client
      # test if all data was indexed by ES, but first refresh manually
      es_client.indices.refresh

      logstash_service.wait_for_logstash
      try(60) do
        begin
          result = es_client.search(index: 'test-index', size: 0, q: '*')
        rescue Elasticsearch::Transport::Transport::Errors::ServiceUnavailable => e
          puts "Elasticsearch unavailable #{e.inspect}"
          hits = 0
        rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
          puts "Index not found"
          hits = 0
        end
        expect(result).to have_hits(1000)
      end

      result = es_client.search(index: 'test-index', size: 1, q: '*')
      s = result["hits"]["hits"][0]["_source"]
      expect(s["mutated"]).to eq("true")
    end
  end

  context 'using pipelines.yml' do
    let!(:pipelines_yaml) { pipelines.to_yaml }
    let!(:pipelines_yaml_file) { ::File.join(settings_dir, "pipelines.yml") }

    before :each do
      IO.write(pipelines_yaml_file, pipelines_yaml)
      logstash_service.spawn_logstash("--path.settings", settings_dir)
    end

    context 'with multiple pipelines' do
      let(:pipelines) {[
          {
              "pipeline.id" => "test",
              "pipeline.workers" => 1,
              "dead_letter_queue.enable" => true,
              "pipeline.batch.size" => 100,
              "config.string" => "input { generator { message => '#{message}' codec => \"json\" count => 1000 } } output { elasticsearch { index => \"test-index\" #{serverless_es_config} } }"
          },
          {
              "pipeline.id" => "test2",
              "pipeline.workers" => 1,
              "dead_letter_queue.enable" => false,
              "pipeline.batch.size" => 100,
              "config.string" => "input { dead_letter_queue { pipeline_id => 'test' path => \"#{dlq_dir}\" commit_offsets => true } } filter { mutate { remove_field => [\"ip\"] add_field => {\"mutated\" => \"true\" } } } output { elasticsearch { index => \"test-index\" #{serverless_es_config} } }"
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
            "pipeline.batch.size" => 100,
            "config.string" => "
                input { generator{ message => '#{message}' codec => \"json\" count => 1000 }
                        dead_letter_queue { path => \"#{dlq_dir}\" commit_offsets => true }
                }
                filter {
                  if ([ip]) { mutate { remove_field => [\"ip\"] add_field => { \"mutated\" => \"true\" } } }
                }
                output { elasticsearch { index => \"test-index\" #{serverless_es_config} } }"
        }
      ]}

      it_behaves_like 'it can send 1000 documents to and index from the dlq'
    end
  end

  context 'using logstash.yml and separate config file' do
    let(:generator_config_file) { config_to_temp_file(@fixture.config("root", { :dlq_dir => dlq_dir })) }

    before :each do
      logstash_service.start_background_with_config_settings(generator_config_file, settings_dir)
    end
    it_behaves_like 'it can send 1000 documents to and index from the dlq'
  end
end
