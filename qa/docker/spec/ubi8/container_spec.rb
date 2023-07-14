require_relative '../spec_helper'
require_relative '../../shared_examples/container_config'
require_relative '../../shared_examples/container_options'
require_relative '../../shared_examples/container'
require_relative '../../shared_examples/xpack'

describe 'A container running the ubi8 image' do
  it_behaves_like 'the container is configured correctly', 'ubi8'
  it_behaves_like 'it runs with different configurations', 'ubi8'
  it_behaves_like 'it applies settings correctly', 'ubi8'
  it_behaves_like 'a container with xpack features', 'ubi8'

  context 'The running container' do
    before do
      @image = find_image('ubi8')
      @container = start_container(@image, {})
    end

    after do
      cleanup_container(@container)
    end

    it 'should be based on Red Hat Enterprise Linux' do
      expect(exec_in_container(@container, 'cat /etc/redhat-release')).to match /Red Hat Enterprise Linux/
    end
  end
end
