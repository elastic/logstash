shared_examples_for 'the container is configured correctly' do |flavor|
  before do
    @image = find_image(flavor)
    @container = create_container(@image, {})
  end

  after do
    cleanup_container(@container)
  end

  context 'logstash' do
    it 'does not warn cannot change locale' do
      expect(@container.logs(stderr: true)).not_to match /cannot change locale/
    end

    it 'should run with the correct version' do
      console_out = exec_in_container(@container, 'logstash --version')
      console_filtered = console_out.split("\n")
            .delete_if do |line|
              line =~ /Using LS_JAVA_HOME defined java|Using system java: /
            end.join
      expect(console_filtered).to match /#{version}/
    end

    it 'should run with the bundled JDK' do
      first_console_line = exec_in_container(@container, 'logstash --version').split("\n")[0]
      expect(first_console_line).to match /Using bundled JDK: \/usr\/share\/logstash\/jdk/
    end

    it 'should be running an API server on port 9600' do
      wait_for_logstash(@container)
      expect(get_logstash_status(@container)).to eql 'green'
    end
  end

  context 'container files' do
    it 'should have the correct license agreement' do
      expect(exec_in_container(@container, 'cat /licenses/LICENSE.txt')).to have_correct_license_agreement(flavor)
    end

    it 'should have the license notices file' do
      expect(exec_in_container(@container, 'cat /licenses/NOTICE.TXT')).to match /Notice for/
    end

    it 'should have the correct user' do
      expect(exec_in_container(@container, 'whoami')).to eql 'logstash'
    end

    it 'should have the correct home directory' do
      expect(exec_in_container(@container, 'printenv HOME')).to eql '/usr/share/logstash'
    end

    it 'should link /opt/logstash to /usr/share/logstash' do
      expect(exec_in_container(@container, 'readlink /opt/logstash')).to eql '/usr/share/logstash'
    end

    it 'should have all files owned by the logstash user' do
      expect(exec_in_container(@container, 'find /usr/share/logstash ! -user logstash')).to be_empty
      expect(exec_in_container(@container, 'find /usr/share/logstash -user logstash')).not_to be_empty
    end

    it 'should have a logstash user with uid 1000' do
      expect(exec_in_container(@container, 'id -u logstash')).to eql '1000'
    end

    it 'should have a logstash user with gid 1000' do
      expect(exec_in_container(@container, 'id -g logstash')).to eql '1000'
    end

    it 'should not have a RollingFile appender' do
      expect(exec_in_container(@container, 'cat /usr/share/logstash/config/log4j2.properties')).not_to match /RollingFile/
    end
  end

  context 'the java process' do
    before do
      wait_for_logstash(@container)
    end

    it 'should be running under the logstash user' do
      expect(java_process(@container, "user")).to eql 'logstash'
    end

    it 'should be running under the logstash group' do
      expect(java_process(@container, "group")).to eql 'logstash'
    end

    it 'should have cgroup overrides set' do
      expect(java_process(@container, "args")).to match /-Dls.cgroup.cpu.path.override=/
      expect(java_process(@container, "args")).to match /-Dls.cgroup.cpuacct.path.override=/
    end

    it 'should have a pid of 1' do
      expect(java_process(@container, "pid")).to eql '1'
    end
  end
end
