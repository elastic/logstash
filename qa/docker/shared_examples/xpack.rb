shared_examples_for 'a container with xpack features' do |flavor|

  before do
    @image = find_image(flavor)
    @container = start_container(@image, {'ENV' => env})
  end

  after do
    cleanup_container(@container)
  end

  context 'when configuring xpack settings' do
    let(:env) { %w(xpack.monitoring.enabled=false xpack.monitoring.elasticsearch.hosts=["http://node1:9200","http://node2:9200"]) }

    it 'persists monitoring environment var keys' do
      # persisting actual value of the environment keys bring the issue where keystore looses its power
      # visit https://github.com/elastic/logstash/issues/15766 for details
      expect(get_settings(@container)['xpack.monitoring.enabled']).to eq("${xpack.monitoring.enabled}")
      expect(get_settings(@container)['xpack.monitoring.elasticsearch.hosts']).to eq("${xpack.monitoring.elasticsearch.hosts}")
    end
  end
end
