require_relative '../spec_helper'
require_relative '../../shared_examples/image_metadata'

describe 'An image with the full distribution' do
  it_behaves_like 'the metadata is set correctly', 'ubi8'

  context 'the ubi8 image should set its specific labels correctly' do
    before do
      @image = find_image('ubi8')
      @image_config = @image.json['Config']
      @labels = @image_config['Labels']
    end

    %w(license org.label-schema.license org.opencontainers.image.licenses).each do |label|
      it "should set the license label #{label} correctly" do
        expect(@labels[label]).to have_correct_license_label('ubi8')
      end
    end

    it 'should set the name label correctly' do
      expect(@labels['name']).to eql "logstash"
    end

    it 'should set the maintainer label correctly' do
      expect(@labels["maintainer"]).to eql "info@elastic.co"
    end

    %w(description summary).each do |label|
      it "should set the name label #{label} correctly" do
        expect(@labels[label]).to eql "Logstash is a free and open server-side data processing pipeline that ingests data from a multitude of sources, transforms it, and then sends it to your favorite 'stash.'"
      end
    end

    it 'should set the vendor label correctly' do
      expect(@labels["vendor"]).to eql "Elastic"
    end
  end
end
