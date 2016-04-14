require_relative '../spec_helper'

describe "test" do
  describe command('ls /foo') do
    its(:stdout) { should match /No such file or directory/ }
  end
end

describe "package" do
  describe package('logstash') do
    it { should be_installed }
  end
end

describe "logstash command" do

  describe command("/opt/logstash/bin/logstash --version") do
    its(:stdout) { should match(/^logstash 3.0.0.dev$/) }
  end
end

describe "plugin manager" do

  describe "install" do
    context "when the plugin exist" do
      describe command("/opt/logstash/bin/plugin install logstash-input-drupal_dblog") do
        its(:stdout) { should match(/^Validating\slogstash-input-drupal_dblog\nInstalling\slogstash-input-drupal_dblog\nInstallation\ssuccessful$/) }
        its(:exit_status) { should eq 0 }
      end
    end
  end

  describe "update" do
    xit "should update all plugins" do
      command("logstash/bin/plugin update")
      expect(true).to eq(true)
    end
  end
end
