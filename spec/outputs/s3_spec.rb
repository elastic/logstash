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
end
