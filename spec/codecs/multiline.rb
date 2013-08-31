require "logstash/codecs/multiline"
require "logstash/event"
require "insist"

describe LogStash::Codecs::Multiline do
  context "#decode" do
    it "should be able to handle multiline events with additional lines space-indented" do
      codec = LogStash::Codecs::Multiline.new("pattern" => "^\\s", "what" => "previous")
      lines = [ "hello world", "   second line", "another first line" ]
      events = []
      lines.each do |line|
        codec.decode(line) do |event|
          events << event
        end
      end
      codec.flush { |e| events << e }
      insist { events.size } == 2
      insist { events[0]["message"] } == "hello world\n   second line"
      insist { events[0]["tags"] }.include?("multiline")
      insist { events[1]["message"] } == "another first line"
      insist { events[1]["tags"] }.nil?
    end

    it "should allow custom tag added to multiline events" do
      codec = LogStash::Codecs::Multiline.new("pattern" => "^\\s", "what" => "previous", "multiline_tag" => "hurray" )
      lines = [ "hello world", "   second line", "another first line" ]
      events = []
      lines.each do |line|
        codec.decode(line) do |event|
          events << event
        end
      end
      codec.flush { |e| events << e }
      insist { events.size } == 2
      insist { events[0]["tags"] }.include?("hurray")
      insist { events[1]["tags"] }.nil?
    end

    it "should allow grok patterns to be used" do
      codec = LogStash::Codecs::Multiline.new(
        "pattern" => "^%{NUMBER} %{TIME}",
        "negate" => true,
        "what" => "previous"
      )

      lines = [ "120913 12:04:33 first line", "second line", "third line" ]

      events = []
      lines.each do |line|
        codec.decode(line) do |event|
          events << event
        end
      end
      codec.flush { |e| events << e }

      insist { events.size } == 1
      insist { events.first["message"] } == lines.join("\n")
    end
  end
end
