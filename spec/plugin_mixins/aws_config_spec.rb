require "spec_helper"
require "logstash/plugin_mixins/aws_config"
require 'aws-sdk'

class DummyInputAwsConfig < LogStash::Inputs::Base
  include LogStash::PluginMixins::AwsConfig

  milestone 1

  def aws_service_endpoint(region)
    { :dummy_input_aws_config_region => "#{region}.awswebservice.local" }
  end
end

describe LogStash::PluginMixins::AwsConfig do
  it 'should support passing credentials as key, value' do
    settings = { 'access_key_id' => '1234',  'secret_access_key' => 'secret' }

    config = DummyInputAwsConfig.new(settings)
    config.aws_options_hash[:access_key_id].should == settings['access_key_id']
    config.aws_options_hash[:secret_access_key].should == settings['secret_access_key']
  end

  it 'should support reading configuration from a yaml file' do
    settings = { 'aws_credentials_file' => File.join(File.dirname(__FILE__), '..', 'support/aws_credentials_file_sample_test.yml') }
    config = DummyInputAwsConfig.new(settings)
    config.aws_options_hash[:access_key_id].should == '1234'
    config.aws_options_hash[:secret_access_key].should == 'secret'
  end

  it 'should call the class to generate the endpoint configuration' do
    settings = { 'access_key_id' => '1234',  'secret_access_key' => 'secret', 'region' => 'us-west-2' }

    config = DummyInputAwsConfig.new(settings)
    config.aws_options_hash[:dummy_input_aws_config_region].should == "us-west-2.awswebservice.local"
  end
end
