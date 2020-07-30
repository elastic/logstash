require_relative '../spec_helper'
require_relative '../../shared_examples/image_metadata'

describe 'A default image' do
  it_behaves_like 'the metadata is set correctly', 'full'
end