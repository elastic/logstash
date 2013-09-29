require "test_utils"
require "logstash/filters/multiline"

puts "MULTILINE FILTER TEST DISABLED"
describe LogStash::Filters::Multiline, :if => false do

  extend LogStash::RSpec

  describe "simple multiline" do
    config <<-CONFIG
    filter {
      multiline {
        pattern => "^\\s"
        what => previous
      }
    }
    CONFIG

    sample [ "hello world", "   second line", "another first line" ] do
      p subject.to_hash
      insist { subject.length } == 2
      insist { subject[0]["message"] } == "hello world\n   second line"
      insist { subject[1]["message"] } == "another first line"
    end
  end

  describe "multiline using grok patterns" do
    config <<-CONFIG
    filter {
      multiline {
        pattern => "^%{NUMBER} %{TIME}"
        negate => true
        what => previous
      }
    }
    CONFIG

    sample [ "120913 12:04:33 first line", "second line", "third line" ] do
      insist { subject.length } == 1
      insist { subject[0]["message"] } ==  "120913 12:04:33 first line\nsecond line\nthird line"
    end
  end

  describe "multiline safety among multiple concurrent streams" do
    config <<-CONFIG
      filter {
        multiline {
          pattern => "^\\s"
          what => previous
        }
      }
    CONFIG

    multiline_event = [
      "hello world",
    ]

    count = 20
    stream_count = 2
    id = 0
    eventstream = count.times.collect do |i|
      stream = "stream#{i % stream_count}"
      (
        [ "hello world #{stream}" ] \
        + rand(5).times.collect { |n| id += 1; "   extra line #{n} in #{stream} event #{id}" }
      ) .collect do |line|
        LogStash::Event.new("message" => line,
                            "host" => stream, "type" => stream,
                            "event" => i)
      end
    end

    alllines = eventstream.flatten

    # Take whole events and mix them with other events (maintain order)
    # This simulates a mixing of multiple streams being received 
    # and processed. It requires that the multiline filter correctly partition
    # by stream_identity
    concurrent_stream = eventstream.flatten.count.times.collect do 
      index = rand(eventstream.count)
      event = eventstream[index].shift
      eventstream.delete_at(index) if eventstream[index].empty?
      event
    end

    sample concurrent_stream do 
      insist { subject.count } == count
      subject.each_with_index do |event, i|
        #puts "#{i}/#{event["event"]}: #{event.to_json}"
        #insist { event.type } == stream
        #insist { event.source } == stream
        insist { event["message"].split("\n").first } =~ /hello world /
      end
    end
  end

  describe "multiline add/remove tags and fields only when matched" do
    config <<-CONFIG
      filter {
        mutate {
          add_tag => "dummy"
        }
        multiline {
          add_tag => [ "nope" ]
          remove_tag => "dummy"
          add_field => [ "dummy2", "value" ]
          pattern => "an unlikely match"
          what => previous
        }
      }
    CONFIG

    sample [ "120913 12:04:33 first line", "120913 12:04:33 second line" ] do
      subject.each do |s|
        insist { s.tags.find_index("nope").nil? && s.tags.find_index("dummy") != nil && !s.fields.has_key?("dummy2") } == true
      end
    end
  end 
end
