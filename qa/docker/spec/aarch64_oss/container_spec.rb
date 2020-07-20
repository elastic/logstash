require_relative '../spec_helper'
require_relative '../../shared_examples/container_config'
require_relative '../../shared_examples/container_options'
require_relative '../../shared_examples/container'

describe 'A container running the aarch64 oss image' do
  it_behaves_like 'the container is configured correctly', 'aarch64-oss'
  it_behaves_like 'it applies settings correctly', 'aarch64-oss'
  it_behaves_like 'it runs with different configurations', 'aarch64-oss'
end