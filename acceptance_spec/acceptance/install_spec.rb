require_relative '../spec_helper_acceptance'

describe "Logstash class:" do

  case fact('osfamily')
  when 'RedHat'
    package_name = 'logstash'
    service_name = 'logstash'
    url          = 'https://s3-us-west-2.amazonaws.com/build.elasticsearch.org/origin/master/nightly/JDK7/logstash-latest.rpm'
    pid_file     = '/var/run/logstash.pid'
  when 'Debian'
    package_name = 'logstash'
    service_name = 'logstash'
    url          = 'https://s3-us-west-2.amazonaws.com/build.elasticsearch.org/origin/master/nightly/JDK7/logstash-latest.deb'
    pid_file     = '/var/run/logstash.pid'
  end

  context "Install Nightly build package" do

    it 'should run successfully' do
      pp = "class { 'logstash': package_url => '#{url}', java_install => true }
            logstash::configfile { 'basic_config': content => 'input { tcp { port => 2000 } } output { stdout { } } ' }
           "

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      sleep 20
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero

    end

    describe package(package_name) do
      it { should be_installed }
    end

    describe service(service_name) do
      it { should be_enabled }
      it { should be_running }
    end

    describe file(pid_file) do
      it { should be_file }
      its(:content) { should match /[0-9]+/ }
    end

    describe port(2000) do
      it {
        sleep 30
        should be_listening
      }
    end

  end

  context "ensure we are still running" do

    describe service(service_name) do
      it {
        sleep 30
        should be_running
      }
    end

    describe port(2000) do
      it { should be_listening }
    end

  end

end
