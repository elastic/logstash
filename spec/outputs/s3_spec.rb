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

    it "normalized the temp directory to include the trailing slash if missing" do
      s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "temp_directory" => "/tmp/logstash" }))
      s3.get_temporary_filename.should == "/tmp/logstash/ls.s3.logstash.local.2015-01-01T00.00.part0.txt"
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

      config = minimal_settings.merge({
        "prefix" => prefix,
        "bucket" => "my-bucket"
      })

      AWS::S3::ObjectCollection.any_instance.should_receive(:[]).with("#{prefix}#{File.basename(fake_data)}") { fake_bucket }

      s3 = LogStash::Outputs::S3.new(config)
      s3.register
      s3.write_on_bucket(fake_data)
    end

    it 'should use the same local filename if no prefix is specified' do
      config = minimal_settings.merge({
        "bucket" => "my-bucket"
      })

      AWS::S3::ObjectCollection.any_instance.should_receive(:[]).with(File.basename(fake_data)) { fake_bucket }

      s3 = LogStash::Outputs::S3.new(minimal_settings)
      s3.register
      s3.write_on_bucket(fake_data)
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

      tmp.read.should == "test-write\n"
      tmp.close
      tmp.unlink
    end
  end

  describe "#rotate_events_log" do
    it "returns true if the tempfile is over the file_size limit" do
      tmp = Tempfile.new('test-append-event')
      tmp.stub(:size) { 2024001 }

      s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "size_file" => 1024 }))
      s3.tempfile = tmp
      s3.rotate_events_log?.should be_true
    end

    it "returns false if the tempfile is under the file_size limit" do
      tmp = Tempfile.new('test-append-event')
      tmp.stub(:size) { 100 }

      s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "size_file" => 1024 }))
      s3.tempfile = tmp
      s3.rotate_events_log?.should be_false
    end
  end

  describe "#move_file_to_bucket" do
    it "should always delete the source file" do
      tmp = Tempfile.new("test-file")
      s3 = LogStash::Outputs::S3.new(minimal_settings)
      s3.register
      allow(File).to receive(:zero?).and_return(true)
      expect(File).to receive(:delete).with(tmp)

      s3.move_file_to_bucket(tmp)
    end

    it 'should not upload the file if the size of the file is zero' do
      tmp = Tempfile.new("test-file")
      allow(tmp).to receive(:zero?).and_return(true)

      s3 = LogStash::Outputs::S3.new(minimal_settings)
      s3.register

      expect(s3).not_to receive(:write_on_bucket)
      s3.move_file_to_bucket(tmp)
    end

    it "should upload the file if the size > 0" do
      tmp = Tempfile.new("test-file")
      allow(File).to receive(:zero?).and_return(false)

      s3 = LogStash::Outputs::S3.new(minimal_settings)
      s3.register

      expect(s3).to receive(:write_on_bucket)

      s3.move_file_to_bucket(tmp)
    end
  end

  describe "#restore_from_crashes" do
    it "read the temp directory and upload the matching file to s3" do
      s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "temp_directory" => "/tmp/"}))

      expect(Dir).to receive(:[]).with("/tmp/*.txt").and_return(["/tmp/01.txt"])
      expect(s3).to receive(:move_file_to_bucket).with("/tmp/01.txt")

      s3.restore_from_crashes()
    end
  end

  describe "#receive" do
    it "should send the event through the codecs" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}, "@timestamp" => "2014-05-30T02:52:17.929Z"}
      event = LogStash::Event.new(data)

      expect_any_instance_of(LogStash::Codecs::Plain).to receive(:encode).with(event)

      s3 = LogStash::Outputs::S3.new(minimal_settings)
      s3.register
      s3.receive(event)
    end
  end
end
