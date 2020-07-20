require_relative '../spec_helper'
require_relative '../../shared_examples/container_config'
require_relative '../../shared_examples/container_options'
require_relative '../../shared_examples/container'
require_relative '../../shared_examples/xpack'

describe 'A container running the full aarch64 image' do
  it_behaves_like 'the container is configured correctly', 'aarch64-full'
  it_behaves_like 'it runs with different configurations', 'aarch64-full'
  it_behaves_like 'it applies settings correctly', 'aarch64-full'
  it_behaves_like 'a container with xpack features', 'aarch64-full'
end