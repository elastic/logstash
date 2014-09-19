# encoding: utf-8
require "spec_helper"
require "logstash/codecs/gzip_lines"
require "logstash/errors"
require "stringio"


describe LogStash::Codecs::GzipLines do
  let!(:uncompressed_log) do
    # Using format from
    # http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
    str = StringIO.new

    str << "2010-03-12   23:51:20   SEA4   192.0.2.147   connect   2014   OK   bfd8a98bee0840d9b871b7f6ade9908f   rtmp://shqshne4jdp4b6.cloudfront.net/cfx/st​  key=value   http://player.longtailvideo.com/player.swf   http://www.longtailvideo.com/support/jw-player-setup-wizard?example=204   LNX%2010,0,32,18   -   -   -   -\n"
    str << "2010-03-12   23:51:21   SEA4   192.0.2.222   play   3914   OK   bfd8a98bee0840d9b871b7f6ade9908f   rtmp://shqshne4jdp4b6.cloudfront.net/cfx/st​  key=value   http://player.longtailvideo.com/player.swf   http://www.longtailvideo.com/support/jw-player-setup-wizard?example=204   LNX%2010,0,32,18   myvideo   p=2&q=4   flv   1\n"

    str.rewind
    str
  end

  describe "#decode" do
    it "should create events from a gzip file" do
      events = []

      subject.decode(compress_with_gzip(uncompressed_log)) do |event|
        events << event
      end

      expect(events.size).to eq(2)
    end
  end
end
