require_relative 'spec_helper'

shared_examples_for "the container is configured correctly" do |flavor|
  include_context "image_context", flavor

  before do
    @container = create_container(@image)
  end

  after  do
    cleanup_container(@container)
  end

  context 'logstash' do
    it "should run with the correct version" do
      expect(exec_in_container(@container, 'logstash --version')).to match /#{version}/
    end

    it 'should be running an API server on port 9600' do
      wait_for_logstash(@container)
      expect(get_logstash_status(@container)).to eql "green"
    end
  end

  context 'container files' do
    it 'should have the correct license agreement' do
      expect(exec_in_container(@container, 'cat /usr/share/logstash/LICENSE.txt')).to have_correct_license_agreement(flavor)
    end

    it 'should have the correct user' do
      expect(exec_in_container(@container, 'whoami').chomp).to eql "logstash"
    end

    it "should have the correct home directory" do
      expect(exec_in_container(@container, 'printenv HOME').chomp).to eql "/usr/share/logstash"
    end

    it "should link /opt/logstash to /usr/share/logstash" do
      expect(exec_in_container(@container, 'readlink /opt/logstash').chomp).to eql "/usr/share/logstash"
    end

    it 'should ensure that all files should be owned by the logstash user' do
      expect(exec_in_container(@container, 'find /usr/share/logstash ! -user logstash')).to be_nil
      expect(exec_in_container(@container, 'find /usr/share/logstash -user logstash')).not_to be_nil
    end

    it 'should ensure that the logstash user is uid 1000' do
      expect(exec_in_container(@container, 'id -u logstash').chomp).to eql "1000"
    end

    it 'should endure that the logstash user is gid 1000' do
      expect(exec_in_container(@container, 'id -g logstash').chomp).to eql "1000"
    end

    it 'should not have a RollingFile appender' do
      expect(exec_in_container(@container, 'cat /usr/share/logstash/config/log4j2.properties')).not_to match /RollingFile/
    end
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
  end
end

context "A container running on a oss image", :oss_image do
  it_behaves_like 'the container is configured correctly', 'oss'
end

context "A container running on a default image", :default_image do
  it_behaves_like 'the container is configured correctly', 'full'
end
