require "logstash/codecs/es_bulk"
require "logstash/event"
require "insist"

describe LogStash::Codecs::ESBulk do
  subject do
    next LogStash::Codecs::ESBulk.new
  end

  context "#decode" do
    it "should return 4 events from json data" do
      data = <<-HERE
      { "index" : { "_index" : "test", "_type" : "type1", "_id" : "1" } }
      { "field1" : "value1" }
      { "delete" : { "_index" : "test", "_type" : "type1", "_id" : "2" } }
      { "create" : { "_index" : "test", "_type" : "type1", "_id" : "3" } }
      { "field1" : "value3" }
      { "update" : {"_id" : "1", "_type" : "type1", "_index" : "index1"} }
      { "doc" : {"field2" : "value2"} }
      HERE

      count = 0
      subject.decode(data) do |event|
        case count
        when 0
          insist { event['@metadata']['_id'] } == "1"
          insist { event['@metadata']['action'] } == "index"
          insist { event['field1'] } == "value1"
        when 1
          insist { event['@metadata']['_id'] } == "2"
          insist { event['@metadata']['action'] } == "delete"
        when 2
          insist { event['@metadata']['_id'] } == "3"
          insist { event['@metadata']['action'] } == "create"
          insist { event['field1'] } == "value3"
        when 3
          insist { event['@metadata']['_id'] } == "1"
          insist { event['@metadata']['action'] } == "update"
          insist { event['doc']['field2'] } == "value2"
        end
        count += 1
      end
      insist { count } == 4
    end
  end

  context "fail to process non-bulk event then continue" do
    it "continues after a fail" do
      decoded = false
      subject.decode("something that isn't a bulk event\n") do |event|
        decoded = true
      end
      insist { decoded } == false
    end
  end

end
