shared_examples_for 'the metadata is set correctly' do |flavor|
  before do
    @image = find_image(flavor)
    @image_config = @image.json['Config']
    @labels = @image_config['Labels']
  end

  it 'should have the correct working directory' do
    expect(@image_config['WorkingDir']).to eql '/usr/share/logstash'
  end

  it "should have an architecture of #{running_architecture}" do
    expect(@image.json['Architecture']).to have_correct_architecture
  end

  %w(org.label-schema.license org.opencontainers.image.licenses).each do |label|
    it "should set the license label #{label} correctly" do
      expect(@labels[label]).to have_correct_license_label(flavor)
    end
  end

  %w(org.label-schema.name org.opencontainers.image.title).each do |label|
    it "should set the name label #{label} correctly" do
      expect(@labels[label]).to eql "logstash"
    end
  end

  it "should set the vendor label org.opencontainers.image.vendor correctly" do
    expect(@labels['org.opencontainers.image.vendor']).to eql "Elastic"
  end

  it "should set the description label org.opencontainers.image.description correctly" do
    expect(@labels['org.opencontainers.image.description']).to eql "Logstash is a free and open server-side data processing pipeline that ingests data from a multitude of sources, transforms it, and then sends it to your favorite 'stash.'"
  end

  %w(org.label-schema.version org.opencontainers.image.version).each do |label|
    it "should set the version label #{label} correctly" do
      expect(@labels[label]).to eql qualified_version
    end
  end
end
