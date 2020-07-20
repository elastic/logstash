require_relative 'spec_helper'

shared_examples_for "the metadata is set correctly" do |flavor|
  include_context "image_context", flavor

  it 'should exist' do
    expect(@image).not_to be_nil
  end

  it 'should have the correct working directory' do
    expect(@image_config['WorkingDir']).to eql '/usr/share/logstash'
  end

  it 'should have the correct Architecture' do
    expect(@image.json['Architecture']).to have_correct_architecture_for_flavor(flavor)
  end

  %w(license org.label-schema.license org.opencontainers.image.licenses).each do |label|
    it "should set the license label #{label} correctly" do
      expect(@labels[label]).to have_correct_license_label(flavor)
    end
  end

  %w(org.label-schema.name org.opencontainers.image.title).each do |label|
    it "should set the name label #{label} correctly" do
      expect(@labels[label]).to eql "logstash"
    end
  end

  %w(org.opencontainers.image.vendor).each do |label|
    it "should set the vendor label #{label} correctly" do
      expect(@labels[label]).to eql "Elastic"
    end
  end

  %w(org.label-schema.version org.opencontainers.image.version).each do |label|
    it "should set the version label #{label} correctly" do
      expect(@labels[label]).to eql qualified_version
    end
  end
end

describe "Oss Docker Image metadata", :oss_image => true do
  it_behaves_like "the metadata is set correctly", 'oss'
end

describe "Default Docker Image metadata", :default_image => true do
  it_behaves_like "the metadata is set correctly", 'full'
end