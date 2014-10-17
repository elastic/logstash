require "spec_helper"
require "logstash/outputs/s3"
require "tempfile"
require 'socket'
require "aws-sdk"

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

  describe "#generate_temporary_filename" do
    before :each do
      Socket.stub(:gethostname) { "logstash.local" }
      Time.stub(:now) { Time.new('2015-10-09-09:00') }
    end

    it "should add tags to the filename if present" do
      config = minimal_settings.merge({ "tags" => ["elasticsearch", "logstash", "kibana"]})
      s3 = LogStash::Outputs::S3.new(config)
      s3.get_temporary_filename.should == "/opt/logstash/S3_temp/ls.s3.logstash.local.2015-01-01T00.00.tag_elasticsearch.logstash.kibana.part0.txt"
    end

    it "should not add the tags to the filename" do
      config = minimal_settings.merge({ "tags" => [] })
      s3 = LogStash::Outputs::S3.new(config)
      s3.get_temporary_filename(3).should == "/opt/logstash/S3_temp/ls.s3.logstash.local.2015-01-01T00.00.part3.txt"
    end

    it "should allow to override the temp directory" do
      config = minimal_settings.merge({ "tags" => [], "temp_directory" => '/tmp/more/' })
      s3 = LogStash::Outputs::S3.new(config)
      s3.get_temporary_filename(2).should == "/tmp/more/ls.s3.logstash.local.2015-01-01T00.00.part2.txt"
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
      s3.register
      s3.write_on_bucket(fake_data, filename)
    end

    it 'should use the same local filename if no prefix is specified' do
      filename = "large-file"

      config = minimal_settings.merge({
        "bucket" => "my-bucket"
      })


      AWS::S3::ObjectCollection.any_instance.should_receive(:[]).with(filename) { fake_bucket }

      s3 = LogStash::Outputs::S3.new(minimal_settings)
      s3.register
      s3.write_on_bucket(fake_data, filename)
    end
  end

  describe "#write_events_to_multiple_files?" do
    it 'returns true if the size_file is != 0 ' do
      s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "size_file" => 200 }))
      s3.write_events_to_multiple_files?.should be_true
    end

    it 'returns false if size_file is zero or not set' do
      s3 = LogStash::Outputs::S3.new(minimal_settings)
      s3.write_events_to_multiple_files?.should be_false
    end
  end


  describe "#write_to_tempfile" do
    it "should append the event to a file" do
      tmp = Tempfile.new('test-append-event')

      s3 = LogStash::Outputs::S3.new(minimal_settings)
      s3.tempfile = tmp
      s3.write_to_tempfile('test-write')

      tmp.read.should == "test-write\n\n"
    end
  end

  describe "#rotate_events_log" do
    it "returns true if the tempfile is over the file_size limit" do
      tmp = Tempfile.new('test-append-event')
      tmp.stub(:size) { 400 }

      s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "size_file" => 200 }))
    end

    it "returns false if the tempfile is under the file_size limit" do
      tmp = Tempfile.new('test-append-event')
      tmp.stub(:size) { 100 }

      s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "size_file" => 200 }))
    end

  end
end
