require_relative 'spec_helper'


shared_examples_for "the process is configured correctly" do |flavor|

  # Use before (:context) here to avoid restarting the container/logstash process for each test,
  # which incurs a multi second (>15s) penalty every time
  before(:context) do
    @image = find_image(flavor)
    @image_config = @image.json['Config']
    @labels = @image_config['Labels']
    @container = start_container(@image, {})
  end

  after(:context) do
    cleanup_container(@container)
  end

  context 'the java process' do
    it 'should be running under the logstash user' do
      expect(java_process(@container, "user")).to eql "logstash"
    end

    it 'should be running under the logstash group' do
      expect(java_process(@container, "group")).to eql "logstash"
    end

    it 'should have the correct args' do
      expect(java_process(@container, "args")).to match /-Dls.cgroup.cpu.path.override=/
      expect(java_process(@container, "args")).to match /-Dls.cgroup.cpuacct.path.override=/
    end

    it 'should have a pid of 1' do
      expect(java_process(@container, "pid")).to eql "1"
    end

    it 'should be running an API server on port 9600' do
      expect(get_logstash_status(@container)).to eql "green"
    end
  end
end

context "A container running on a oss image", :oss_image => true do
  it_behaves_like "the process is configured correctly", 'oss'
end

context "A container running on a default image", :default_image => true do
  it_behaves_like 'the process is configured correctly', 'full'
end
