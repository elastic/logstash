require "test_utils"
require "logstash/filters/multiline"

describe LogStash::Filters::Multiline do
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
      insist { subject.length } == 2
      insist { subject[0].message } == "hello world\n   second line"
      insist { subject[1].message } == "another first line"
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
      reject { subject}.is_a? Array
      insist { subject.message } ==  "120913 12:04:33 first line\nsecond line\nthird line"
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
        LogStash::Event.new("@message" => line,
                            "@source" => stream, "@type" => stream,
                            "@fields" => { "event" => i })
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
        insist { event.message.split("\n").first } =~ /hello world /
      end
    end
  end
end
