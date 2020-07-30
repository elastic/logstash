require_relative 'spec_helper'

shared_examples_for 'it runs when configured correctly' do |flavor|
  include_context "image_context", flavor

  before do
    @container = start_container(@image, options)
  end

  after do
    cleanup_container(@container)
  end

  context 'when a single pipeline is configured via volume bind' do
    let(:options) { {"HostConfig" => { "Binds" => ["#{FIXTURES_DIR}/simple_pipeline/:/usr/share/logstash/pipeline/"] } } }

    it "should show the stats for that pipeline" do
      expect(get_node_stats(@container)['pipelines']['main']['plugins']['inputs'][0]['id']).to eq 'simple_pipeline'
    end
  end

  context 'when multiple pipelines are configured via volume bind' do
    let(:options) { {"HostConfig" => { "Binds" => ["#{FIXTURES_DIR}/multiple_pipelines/pipelines/:/usr/share/logstash/pipeline/",
                                                   "#{FIXTURES_DIR}/multiple_pipelines/config/pipelines.yml:/usr/share/logstash/config/pipelines.yml"] } } }

    it "should show stats for both pipelines" do
      expect(get_node_stats(@container)['pipelines']['pipeline_one']['plugins']['inputs'][0]['id']).to eq 'multi_pipeline1'
      expect(get_node_stats(@container)['pipelines']['pipeline_two']['plugins']['inputs'][0]['id']).to eq 'multi_pipeline2'
    end
  end

  context 'when a custom `logstash.yml` is configured via volume bind' do
    let(:options) { {"HostConfig" => { "Binds" => ["#{FIXTURES_DIR}/custom_logstash_yml/logstash.yml:/usr/share/logstash/config/logstash.yml"] } } }

    it "should change the value of pipeline.batch.size" do
      expect(get_node_info(@container)['pipelines']['main']['batch_size']).to eq 200
    end
  end
end

describe "A container running on a default image", :default_image do
  it_behaves_like 'it runs when configured correctly', 'full'
end

describe "A container running on an oss image", :oss_image do
  it_behaves_like 'it runs when configured correctly', 'oss'
end