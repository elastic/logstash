require_relative '../spec_helper'
require_relative '../../shared_examples/container_config'
require_relative '../../shared_examples/container_options'
require_relative '../../shared_examples/container'

describe 'A container running the oss image' do
  it_behaves_like 'the container is configured correctly', 'oss'
  it_behaves_like 'it applies settings correctly', 'oss'
  it_behaves_like 'it runs with different configurations', 'oss'
end