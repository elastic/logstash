require_relative '../spec_helper'
require_relative '../../shared_examples/container_config'
require_relative '../../shared_examples/container_options'
require_relative '../../shared_examples/container'
require_relative '../../shared_examples/xpack'

describe 'A container running the Chainguard image' do
  it_behaves_like 'the container is configured correctly', 'cgr'
  it_behaves_like 'it runs with different configurations', 'cgr'
  it_behaves_like 'it applies settings correctly', 'cgr'
  it_behaves_like 'a container with xpack features', 'cgr'

  context 'The running container' do
    before do
      @image = find_image('cgr')
      @container = start_container(@image, {})
    end

    after do
      cleanup_container(@container)
    end

    it 'has a Chainguard base image' do
      expect(exec_in_container(@container, 'cat /etc/os-release').chomp).to match /Chainguard/
    end
  end
end
