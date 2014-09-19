# encoding: utf-8
require "spec_helper"
require "logstash/codecs/cloudfront"
require "logstash/errors"
require "stringio"
require "zlib"

describe LogStash::Codecs::Cloudfront do
  let!(:uncompressed_cloudfront_log) do
    # Using format from
    # http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
    str = StringIO.new

    str << "#Version: 1.0\n"
    str << "#Fields: date time x-edge-location c-ip x-event sc-bytes x-cf-status x-cf-client-id cs-uri-stem cs-uri-query c-referrer x-page-url​  c-user-agent x-sname x-sname-query x-file-ext x-sid\n"
    str << "2010-03-12   23:51:20   SEA4   192.0.2.147   connect   2014   OK   bfd8a98bee0840d9b871b7f6ade9908f   rtmp://shqshne4jdp4b6.cloudfront.net/cfx/st​  key=value   http://player.longtailvideo.com/player.swf   http://www.longtailvideo.com/support/jw-player-setup-wizard?example=204   LNX%2010,0,32,18   -   -   -   -\n"
    str << "2010-03-12   23:51:21   SEA4   192.0.2.222   play   3914   OK   bfd8a98bee0840d9b871b7f6ade9908f   rtmp://shqshne4jdp4b6.cloudfront.net/cfx/st​  key=value   http://player.longtailvideo.com/player.swf   http://www.longtailvideo.com/support/jw-player-setup-wizard?example=204   LNX%2010,0,32,18   myvideo   p=2&q=4   flv   1\n"

    str.rewind
    str
  end

  describe "#decode" do
    it "should create events from a gzip file" do
      events = []

      subject.decode(compress_with_gzip(uncompressed_cloudfront_log)) do |event|
        events << event
      end

      expect(events.size).to eq(2)
    end

    it 'should extract the metadata of the file' do
      events = []

      subject.decode(compress_with_gzip(uncompressed_cloudfront_log)) do |event|
        events << event
      end

      expect(events.first["cloudfront_version"]).to eq("1.0")
      expect(events.first["cloudfront_fields"]).to eq("date time x-edge-location c-ip x-event sc-bytes x-cf-status x-cf-client-id cs-uri-stem cs-uri-query c-referrer x-page-url​  c-user-agent x-sname x-sname-query x-file-ext x-sid")
    end
  end

  describe "#extract_version" do
    it "returns the version from a matched string" do
      line = "#Version: 1.0"

      expect(subject.extract_version(line)).to eq("1.0")
    end

    it "doesn't return anything if version isnt matched" do
      line = "Bleh my string"
      expect(subject.extract_version(line)).to eq(nil)
    end

    it "doesn't match if #Version is not at the beginning of the string" do
      line = "2010-03-12   23:53:44   SEA4   192.0.2.4   stop   323914   OK   bfd8a98bee0840d9b871b7f6ade9908f #Version: 1.0 Bleh blah"
      expect(subject.extract_version(line)).to eq(nil)
    end
  end

  describe "#extract_fields" do
    it "return a string with all the fields" do
      line = "#Fields: date time x-edge-location c-ip x-event sc-bytes x-cf-status x-cf-client-id cs-uri-stem cs-uri-query c-referrer x-page-url​  c-user-agent x-sname x-sname-query x-file-ext x-sid"
      expect(subject.extract_fields(line)).to eq("date time x-edge-location c-ip x-event sc-bytes x-cf-status x-cf-client-id cs-uri-stem cs-uri-query c-referrer x-page-url​  c-user-agent x-sname x-sname-query x-file-ext x-sid")
    end

    it "doesn't return anything if we can the fields list" do
      line = "Bleh my string"
      expect(subject.extract_fields(line)).to eq(nil)
    end

    it "doesnt match if #Fields: is not at the beginning of the string" do
      line = "2010-03-12   23:53:44   SEA4   192.0.2.4   stop   323914   OK   bfd8a98bee0840d9b871b7f6ade9908f #Fields: 1.0 Bleh blah"
      expect(subject.extract_fields(line)).to eq(nil)
    end
  end
end
