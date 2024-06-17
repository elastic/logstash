require_relative '../spec_helper'
require_relative '../../shared_examples/container_config'
require_relative '../../shared_examples/container_options'
require_relative '../../shared_examples/container'
require_relative '../../shared_examples/xpack'

describe 'A container running the wolfi image' do
  it_behaves_like 'the container is configured correctly', 'wolfi'
  it_behaves_like 'it runs with different configurations', 'wolfi'
  it_behaves_like 'it applies settings correctly', 'wolfi'
  it_behaves_like 'a container with xpack features', 'wolfi'

  context 'The running container' do
    before do
      @image = find_image('wolfi')
      @container = start_container(@image, {})
    end

    after do
      cleanup_container(@container)
    end

    it 'should be based on Wolfi' do
      expect(exec_in_container(@container, 'cat /etc/os-release')).to match /Wolfi|Chainguard/
    end
  end
end
