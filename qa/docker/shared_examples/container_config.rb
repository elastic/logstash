shared_examples_for 'it runs with different configurations' do |flavor|
  before do
    @image = find_image(flavor)
    @container = start_container(@image, options)
  end

  after do
    cleanup_container(@container)
  end

  context 'when a single pipeline is configured via volume bind' do
    let(:options) { {"HostConfig" => { "Binds" => ["#{FIXTURES_DIR}/simple_pipeline/:/usr/share/logstash/pipeline/"] } } }

    it 'should show the stats for that pipeline' do
      wait_for_pipeline(@container)
      expect(get_plugin_info(@container, 'inputs', 'simple_pipeline')).not_to be nil
    end
  end

  context 'when multiple pipelines are configured via volume bind' do
    let(:options) { {"HostConfig" => { "Binds" => ["#{FIXTURES_DIR}/multiple_pipelines/pipelines/:/usr/share/logstash/pipeline/",
                                                   "#{FIXTURES_DIR}/multiple_pipelines/config/pipelines.yml:/usr/share/logstash/config/pipelines.yml"] } } }

    it "should show stats for both pipelines" do
      wait_for_pipeline(@container, 'pipeline_one')
      wait_for_pipeline(@container, 'pipeline_two')
      expect(get_plugin_info(@container, 'inputs', 'multi_pipeline1', 'pipeline_one')).not_to be nil
      expect(get_plugin_info(@container, 'inputs', 'multi_pipeline2', 'pipeline_two')).not_to be nil
    end
  end

  context 'when a custom `logstash.yml` is configured via volume bind' do
    let(:options) { {"HostConfig" => { "Binds" => ["#{FIXTURES_DIR}/custom_logstash_yml/logstash.yml:/usr/share/logstash/config/logstash.yml"] } } }

    it 'should change the value of pipeline.batch.size' do
      wait_for_pipeline(@container)
      expect(get_pipeline_setting(@container, 'batch_size')).to eq 200
    end
  end
end
