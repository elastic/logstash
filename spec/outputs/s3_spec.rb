require "spec_helper"
require "logstash/outputs/s3"
require 'socket'
require "aws-sdk"
require "fileutils"
require "stud/temporary"

describe LogStash::Outputs::S3 do
  before do
    # We stub all the calls from S3, for more information see:
    # http://ruby.awsblog.com/post/Tx2SU6TYJWQQLC3/Stubbing-AWS-Responses
    AWS.stub!
  end

  let(:minimal_settings)  {  { "access_key_id" => "1234",
                               "secret_access_key" => "secret",
                               "bucket" => "my-bucket" } }

  describe "configuration" do
    it "should support the deprecated endpoint_region as a configuration option" do
      config = { "endpoint_region" => "sa-east-1" }
      s3 = LogStash::Outputs::S3.new(config)
      expect(s3.aws_options_hash[:s3_endpoint]).to eq("s3-sa-east-1.amazonaws.com")
    end

    it "should use the depracated option before failling back to the region" do
      config = { "region" => "us-east-1", "endpoint_region" => "sa-east-1" }
      s3 = LogStash::Outputs::S3.new(config)
      expect(s3.aws_options_hash[:s3_endpoint]).to eq("s3-sa-east-1.amazonaws.com")
    end
  end

  describe "#register" do
    it "should create the tmp directory if it doesn't exist" do
      temporary_directory = Stud::Temporary.pathname("temporary_directory")

      config = {
        "access_key_id" => "1234",
        "secret_access_key" => "secret",
        "bucket" => "logstash",
        "size_file" => 10,
        "temporary_directory" => temporary_directory
      }

      s3 = LogStash::Outputs::S3.new(config)
      allow(s3).to receive(:test_s3_write)
      s3.register

      expect(Dir.exist?(temporary_directory)).to eq(true)
      FileUtils.rm_r(temporary_directory)
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
    before do
      Socket.stub(:gethostname) { "logstash.local" }
      Time.stub(:now) { Time.new('2015-10-09-09:00') }
    end

    it "should add tags to the filename if present" do
      config = minimal_settings.merge({ "tags" => ["elasticsearch", "logstash", "kibana"], "temporary_directory" => "/tmp/logstash"})
      s3 = LogStash::Outputs::S3.new(config)
      expect(s3.get_temporary_filename).to eq("/tmp/logstash/ls.s3.logstash.local.2015-01-01T00.00.tag_elasticsearch.logstash.kibana.part0.txt")
    end

    it "should not add the tags to the filename" do
      config = minimal_settings.merge({ "tags" => [], "temporary_directory" => "/tmp/logstash" })
      s3 = LogStash::Outputs::S3.new(config)
      expect(s3.get_temporary_filename(3)).to eq("/tmp/logstash/ls.s3.logstash.local.2015-01-01T00.00.part3.txt")
    end

    it "should default to the os temporary directory" do
      config = minimal_settings.merge({ "tags" => [] })
      s3 = LogStash::Outputs::S3.new(config)
      expect(s3.get_temporary_filename(2)).to eq(File.join(Dir.tmpdir, "logstash", "ls.s3.logstash.local.2015-01-01T00.00.part2.txt"))
    end

    it "normalized the temp directory to include the trailing slash if missing" do
      s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "temporary_directory" => "/tmp/logstash" }))
      expect(s3.get_temporary_filename).to eq("/tmp/logstash/ls.s3.logstash.local.2015-01-01T00.00.part0.txt")
    end
  end

  describe "#write_on_bucket" do
    after(:all) do
      File.unlink(fake_data.path)
    end

    let!(:fake_data) { Stud::Temporary.file }

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

      expect_any_instance_of(AWS::S3::ObjectCollection).to receive(:[]).with("#{prefix}#{File.basename(fake_data)}") { fake_bucket }

      s3 = LogStash::Outputs::S3.new(config)
      allow(s3).to receive(:test_s3_write)
      s3.register
      s3.write_on_bucket(fake_data)
    end

    it 'should use the same local filename if no prefix is specified' do
      config = minimal_settings.merge({
        "bucket" => "my-bucket"
      })

      expect_any_instance_of(AWS::S3::ObjectCollection).to receive(:[]).with(File.basename(fake_data)) { fake_bucket }

      s3 = LogStash::Outputs::S3.new(minimal_settings)
      allow(s3).to receive(:test_s3_write)
      s3.register
      s3.write_on_bucket(fake_data)
    end
  end

  describe "#write_events_to_multiple_files?" do
    it 'returns true if the size_file is != 0 ' do
      s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "size_file" => 200 }))
      expect(s3.write_events_to_multiple_files?).to eq(true)
    end

    it 'returns false if size_file is zero or not set' do
      s3 = LogStash::Outputs::S3.new(minimal_settings)
      expect(s3.write_events_to_multiple_files?).to eq(false)
    end
  end

  describe "#write_to_tempfile" do
    it "should append the event to a file" do
      Stud::Temporary.file("logstash", "a+") do |tmp|
        s3 = LogStash::Outputs::S3.new(minimal_settings)
        allow(s3).to receive(:test_s3_write)
        s3.register
        s3.tempfile = tmp
        s3.write_to_tempfile("test-write")
        tmp.rewind
        expect(tmp.read).to eq("test-write")
      end
    end
  end

  describe "#rotate_events_log" do
    it "returns true if the tempfile is over the file_size limit" do
      Stud::Temporary.file do |tmp|
        tmp.stub(:size) { 2024001 }

        s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "size_file" => 1024 }))
        s3.tempfile = tmp
        expect(s3.rotate_events_log?).to be(true)
      end
    end

    it "returns false if the tempfile is under the file_size limit" do
      Stud::Temporary.file do |tmp|
        tmp.stub(:size) { 100 }

        s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "size_file" => 1024 }))
        s3.tempfile = tmp
        expect(s3.rotate_events_log?).to eq(false)
      end
    end
  end

  describe "#move_file_to_bucket" do
    let!(:s3) { LogStash::Outputs::S3.new(minimal_settings) }

    before do
      # Assume the AWS test credentials pass.
      allow(s3).to receive(:test_s3_write)
      s3.register
    end

    it "should always delete the source file" do
      tmp = Stud::Temporary.file

      allow(File).to receive(:zero?).and_return(true)
      expect(File).to receive(:delete).with(tmp)

      s3.move_file_to_bucket(tmp)
    end

    it 'should not upload the file if the size of the file is zero' do
      temp_file = Stud::Temporary.file
      allow(temp_file).to receive(:zero?).and_return(true)

      expect(s3).not_to receive(:write_on_bucket)
      s3.move_file_to_bucket(temp_file)
    end

    it "should upload the file if the size > 0" do
      tmp = Stud::Temporary.file

      allow(File).to receive(:zero?).and_return(false)
      expect(s3).to receive(:write_on_bucket)

      s3.move_file_to_bucket(tmp)
    end
  end

  describe "#restore_from_crashes" do
    it "read the temp directory and upload the matching file to s3" do
      s3 = LogStash::Outputs::S3.new(minimal_settings.merge({ "temporary_directory" => "/tmp/logstash/" }))

      expect(Dir).to receive(:[]).with("/tmp/logstash/*.txt").and_return(["/tmp/logstash/01.txt"])
      expect(s3).to receive(:move_file_to_bucket_async).with("/tmp/logstash/01.txt")


      s3.restore_from_crashes
    end
  end

  describe "#receive" do
    it "should send the event through the codecs" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}, "@timestamp" => "2014-05-30T02:52:17.929Z"}
      event = LogStash::Event.new(data)

      expect_any_instance_of(LogStash::Codecs::Plain).to receive(:encode).with(event)

      s3 = LogStash::Outputs::S3.new(minimal_settings)
      allow(s3).to receive(:test_s3_write)
      s3.register

      s3.receive(event)
    end
  end
end
