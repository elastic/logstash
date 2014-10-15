require "spec_helper"
require "logstash/outputs/s3"
require "aws-sdk"
require "tempfile"

describe LogStash::Outputs::S3 do
  before { AWS.stub! }
  let(:minimal_settings)  {  { "access_key_id" => "1234",
                               "secret_access_key" => "secret",
                               "bucket" => "my-bucket" } }

  describe "configuration" do
    it "should support the deprecated endpoint_region as a configuration option" do
      config = { "endpoint_region" => "sa-east-1" }
      s3 = LogStash::Outputs::S3.new(config)
      s3.aws_options_hash[:s3_endpoint].should == "s3-sa-east-1.amazonaws.com"
    end

    it "should use the depracated option before failling back to the region" do
      config = { "region" => "us-east-1", "endpoint_region" => "sa-east-1" }
      s3 = LogStash::Outputs::S3.new(config)
      s3.aws_options_hash[:s3_endpoint].should == "s3-sa-east-1.amazonaws.com"
    end
  end

  describe "format_message" do
    it 'should accept a nil list of tags' do
      event = {}
      LogStash::Outputs::S3.format_message(event).should match(/\nTags:\s\n/)
    end

    it 'should accept a list of muliples tags' do
      event = { "tags" => ["elasticsearch", "logstash", "kibana"] }
      LogStash::Outputs::S3.format_message(event).should match(/\nTags:\selasticsearch,\slogstash,\skibana\n/)
    end
  end

  describe "#register" do
    it "should raise a ConfigurationError if the tmp directory doesn't exist" do

      config = {
        "access_key_id" => "1234",
        "secret_access_key" => "secret",
        "bucket" => "logstash",
        "time_file" => 1,
        "size_file" => 10,
        "temp_directory" => "/tmp/logstash-do-not-exist"
      }

      s3 = LogStash::Outputs::S3.new(config)

      expect {
        s3.register
      }.to raise_error(LogStash::ConfigurationError)
    end

    it "should raise a ConfigurationError if the prefix contains one or more '\^`><' characters" do
      config = {
        "prefix" => "`no\><^"
      }

      s3 = LogStash::Outputs::S3.new(config)

      expect {
        s3.register
      }.to raise_error(LogStash::ConfigurationError)
    end
  end

  describe "#write_on_bucket" do
    let(:fake_data) { Tempfile.new("fake_data") }
    let(:fake_bucket) do
      s3 = double('S3Object')
      s3.stub(:write)
      s3
    end

    it "should prefix the file on the bucket if a prefix is specified" do
      prefix = "my-prefix"
      filename = "large-file"

      config = minimal_settings.merge({
        "prefix" => prefix,
        "bucket" => "my-bucket"
      })



      AWS::S3::ObjectCollection.any_instance.should_receive(:[]).with("#{prefix}#{filename}") { fake_bucket }

      s3 = LogStash::Outputs::S3.new(config)
      s3.write_on_bucket(fake_data, filename)
    end

    it 'should use the same local filename if no prefix is specified' do
      filename = "large-file"

      config = minimal_settings.merge({
        "bucket" => "my-bucket"
      })


      AWS::S3::ObjectCollection.any_instance.should_receive(:[]).with(filename) { fake_bucket }

      s3 = LogStash::Outputs::S3.new(minimal_settings)
      s3.write_on_bucket(fake_data, filename)
    end
  end
end
