shared_examples_for 'it applies settings correctly' do |flavor|
  before do
    @image = find_image(flavor)
    @container = start_container(@image, options)
    wait_for_pipeline(@container)
  end

  after do
    cleanup_container(@container)
  end

  context 'when setting pipeline workers shell style' do
    let(:options) { { 'ENV' => ['PIPELINE_WORKERS=32'] } }

    it "should correctly set the number of pipeline workers" do
      expect(get_pipeline_setting(@container, 'workers')).to eql 32
    end
  end

  context 'when setting pipeline workers dot style' do
    let(:options) { { 'ENV' => ['pipeline.workers=64'] } }

    it "should correctly set the number of pipeline workers" do
      expect(get_pipeline_setting(@container, 'workers')).to eql 64
    end
  end

  context 'when setting pipeline batch size' do
    let(:options) { { 'ENV' => ['pipeline.batch.size=123'] } }

    it "should correctly set the batch size" do
      expect(get_pipeline_setting(@container, 'batch_size')).to eql 123
    end
  end

  context 'when setting pipeline batch output chunking trigger factor' do
    let(:options) { { 'ENV' => ['pipeline.batch.output_chunking_trigger_factor=5'] } }

    it "should correctly set the batch output chunking trigger factor" do
      expect(get_pipeline_setting(@container, 'batch_output_chunking_trigger_factor')).to eql 5
    end
  end

  context 'when setting pipeline batch delay' do
    let(:options) { { 'ENV' => ['pipeline.batch.delay=36'] } }

    it 'should correctly set batch delay' do
      expect(get_pipeline_setting(@container, 'batch_delay')).to eql 36
    end
  end

  context 'when setting unsafe shutdown to true shell style' do
    let(:options) { { 'ENV' => ['pipeline.unsafe_shutdown=true'] } }

    it 'should set unsafe shutdown to true' do
      expect(get_settings(@container)['pipeline.unsafe_shutdown']).to be_truthy
    end
  end

  context 'when setting unsafe shutdown to true dot style' do
    let(:options) { { 'ENV' => ['pipeline.unsafe_shutdown=true'] } }

    it 'should set unsafe shutdown to true' do
      expect(get_settings(@container)['pipeline.unsafe_shutdown']).to be_truthy
    end
  end

  context 'when setting config.string' do
    let(:options) {
      {
        'ENV' => [
          'USER=kimchy',
          'CONFIG_STRING=input {
              beats { port => 5040 }
            }
            output {
              elasticsearch {
                hosts => ["https://es:9200"]
                user => "${USER}"
                password => \'changeme\'
              }
            }'
        ]
      }
    }

    it "persists ${CONFIG_STRING} key in logstash.yml, resolves when running and spins up without issue" do
      settings = get_settings(@container)
      expect(settings['config.string']).to eq("${CONFIG_STRING}")

      pipeline_config = get_pipeline_stats(@container)
      input_plugins = pipeline_config.dig('plugins', 'inputs')
      expect(input_plugins[0].dig('name')).to eql('beats')

      output_plugins = pipeline_config.dig('plugins', 'outputs')
      expect(output_plugins[0].dig('name')).to eql('elasticsearch')

      # check if logs contain the ES request with the resolved ${USER}
      wait_for_log_message(@container, 'https://kimchy:xxxxxx@es:9200')
    end
  end
end
