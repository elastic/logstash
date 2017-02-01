require "logstash/codecs/msgpack_feed"
require "logstash/event"
require "insist"

describe LogStash::Codecs::MsgpackFeed do
  subject do
    next LogStash::Codecs::MsgpackFeed.new
  end

  context "#decode" do
    it "should return three events from a msgpack feed" do
      # Msgpack of:
      # {"message": "one"}{"message": "two"}{"message": "three"}
      data = "\x81\xA7message\xA3one\x81\xA7message\xA3two\x81\xA7message\xA5three".bytes.to_a

      res = Array.new
      subject.decode(data[0..6].pack('c*')) do |event|
        res.push event
      end
      subject.decode(data[7..-4].pack('c*')) do |event|
        res.push event
      end
      subject.decode(data[-3..-1].pack('c*')) do |event|
        res.push event
      end

      insist { res.size } == 3

      expected = ["one", "two", "three"]
      expected.each_index {|i|
        event = res[i]
        insist { event.is_a? LogStash::Event }
        insist { event["message"] } == expected[i]
      }
    end
  end

end
