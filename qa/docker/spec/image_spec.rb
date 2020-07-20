require "serverspec"
require_relative 'spec_helper'

shared_examples_for 'the image is configured correctly' do  |flavor|

  before (:context) do
    @image = find_image(flavor)
    @image_config = @image.json['Config']
    @labels = @image_config['Labels']
    set :backend, :docker
    set :docker_image, @image.id
  end

  after (:context) do
      Specinfra::Configuration.instance_variable_set("@docker_image", nil)
      Specinfra::Backend::Docker.clear
      set :backend, :exec
  end

  it 'should have the correct license agreement' do
    expect(file('cat /usr/share/logstash/LICENSE.txt').content).to have_correct_license_agreement(flavor)
  end

  it 'should have the correct version' do
    expect(command('logstash --version').stdout).to match /#{version}/
  end

  it 'should have the correct user' do
    expect(command('whoami').stdout).to match /logstash/
  end

  it "should have the correct home directory" do
    expect(command('echo $HOME').stdout.chomp).to eq "/usr/share/logstash"
  end

  it "should set opt/logstash as a symlink" do
    expect(file('/opt/logstash').symlink?).to be_truthy
    expect(file('/opt/logstash').link_target).to eq "/usr/share/logstash"
  end

  it 'should ensure that all files should be owned by the logstash user' do
    expect(command('find /usr/share/logstash ! -user logstash').stdout).to be_empty
  end

  it 'should ensure that the logstash user is uid 1000' do
    expect(command('id -u logstash').stdout.chomp).to eq "1000"
  end

  it 'should endure that the logstash user is gid 1000' do
    expect(command('id -g logstash').stdout.chomp).to eq "1000"
  end

  it 'should not have a RollingFile appender' do
    expect(file('/usr/share/logstash/config/log4j2.properties').content).not_to match /RollingFile/
  end
end

context "an oss docker image", :oss_image => true do
  it_behaves_like 'the image is configured correctly', 'oss'
end

context "a default docker image", :default_image => true do
  it_behaves_like 'the image is configured correctly', 'full'
end
