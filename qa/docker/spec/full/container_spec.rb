require_relative '../spec_helper'
require_relative '../../shared_examples/container_config'
require_relative '../../shared_examples/container_options'
require_relative '../../shared_examples/container'
require_relative '../../shared_examples/xpack'

describe 'A container running the full image' do
  # it_behaves_like 'the container is configured correctly', 'full'
  it_behaves_like 'it runs with different configurations', 'full'
  # it_behaves_like 'it applies settings correctly', 'full'
  # it_behaves_like 'a container with xpack features', 'full'
end