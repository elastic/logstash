require_relative '../spec_helper'
require_relative '../../shared_examples/container_config'
require_relative '../../shared_examples/container_options'
require_relative '../../shared_examples/container'

describe 'A container running the oss image' do
  it_behaves_like 'the container is configured correctly', 'oss'
  it_behaves_like 'it applies settings correctly', 'oss'
  it_behaves_like 'it runs with different configurations', 'oss'

  context 'The running container' do
    before do
      @image = find_image('oss')
      @container = start_container(@image, {})
    end

    after do
      cleanup_container(@container)
    end

    it 'has an Ubuntu 20.04 base image' do
      expect(exec_in_container(@container, 'cat /etc/os-release').chomp).to match /Ubuntu 20.04/
    end
  end
end
