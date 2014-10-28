require "logstash/codecs/es_bulk"
require "logstash/event"
#require "logstash/json"
require "insist"

describe LogStash::Codecs::ESBulk do
  subject do
    next LogStash::Codecs::ESBulk.new
  end

  context "#decode" do
    it "should return an event from json data" do
      count = 0
      data = <<-HERE
      { "index" : { "_index" : "test", "_type" : "type1", "_id" : "1" } }
      { "field1" : "value1" }
      { "delete" : { "_index" : "test", "_type" : "type1", "_id" : "2" } }
      { "create" : { "_index" : "test", "_type" : "type1", "_id" : "3" } }
      { "field1" : "value3" }
      { "update" : {"_id" : "1", "_type" : "type1", "_index" : "index1"} }
      { "doc" : {"field2" : "value2"} }
      HERE

      subject.decode(data) do |event|
        count += 1
      end
      insist { count } == 4
    end

#    context "processing plain text" do
#      it "falls back to plain text" do
#        decoded = false
#        subject.decode("something that isn't json\n") do |event|
#          decoded = true
#          insist { event.is_a?(LogStash::Event) }
#          insist { event["message"] } == "something that isn't json"
#        end
#        insist { decoded } == true
#      end
#    end
  end
end
