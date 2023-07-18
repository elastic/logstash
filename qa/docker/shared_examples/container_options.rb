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
end
