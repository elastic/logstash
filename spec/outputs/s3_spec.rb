require "spec_helper"
require "logstash/outputs/s3"

describe LogStash::Outputs::S3 do
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
    it "should raise a Configuration error if the tmp directory doesn't exist" do

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
  end
end
