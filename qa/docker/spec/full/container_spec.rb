require_relative '../spec_helper'
require_relative '../../shared_examples/container_config'
require_relative '../../shared_examples/container_options'
require_relative '../../shared_examples/container'

describe 'A container running the full image' do
  it_behaves_like 'the container is configured correctly', 'full'
  it_behaves_like 'it runs with different configurations', 'full'
  it_behaves_like 'it applies settings correctly', 'full'

  context 'when configuring xpack settings' do
    before do
      @image = find_image('full')
      @container = start_container(@image, {'ENV' => env})
    end

    after do
      cleanup_container(@container)
    end

    context 'when disabling xpack monitoring' do
      let(:env) {['xpack.monitoring.enabled=false']}

      it 'should set monitoring to false' do
        expect(get_settings(@container)['xpack.monitoring.enabled']).to be_falsey
      end
    end

    context 'when enabling xpack monitoring' do
      let(:env) {['xpack.monitoring.enabled=true']}

      it 'should set monitoring to true' do
        expect(get_settings(@container)['xpack.monitoring.enabled']).to be_truthy
      end
    end

    context 'when setting elasticsearch urls as an array' do
      let(:env) { ['xpack.monitoring.elasticsearch.hosts=["http://node1:9200","http://node2:9200"]']}

      it 'should set set the hosts property correctly' do
        expect(get_settings(@container)['xpack.monitoring.elasticsearch.hosts']).to be_an(Array)
        expect(get_settings(@container)['xpack.monitoring.elasticsearch.hosts']).to include('http://node1:9200')
        expect(get_settings(@container)['xpack.monitoring.elasticsearch.hosts']).to include('http://node2:9200')
      end
    end
  end
end