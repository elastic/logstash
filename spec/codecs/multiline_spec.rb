# encoding: utf-8

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


    context "using default UTF-8 charset" do

      it "should decode valid UTF-8 input" do
        codec = LogStash::Codecs::Multiline.new("pattern" => "^\\s", "what" => "previous")
        lines = [ "foobar", "κόσμε" ]
        events = []
        lines.each do |line|
          insist { line.encoding.name } == "UTF-8"
          insist { line.valid_encoding? } == true

          codec.decode(line) { |event| events << event }
        end
        codec.flush { |e| events << e }
        insist { events.size } == 2

        events.zip(lines).each do |tuple|
          insist { tuple[0]["message"] } == tuple[1]
          insist { tuple[0]["message"].encoding.name } == "UTF-8"
        end
      end

      it "should escape invalid sequences" do
        codec = LogStash::Codecs::Multiline.new("pattern" => "^\\s", "what" => "previous")
        lines = [ "foo \xED\xB9\x81\xC3", "bar \xAD" ]
        events = []
        lines.each do |line|
          insist { line.encoding.name } == "UTF-8"
          insist { line.valid_encoding? } == false

          codec.decode(line) { |event| events << event }
        end
        codec.flush { |e| events << e }
        insist { events.size } == 2

        events.zip(lines).each do |tuple|
          insist { tuple[0]["message"] } == tuple[1].inspect[1..-2]
          insist { tuple[0]["message"].encoding.name } == "UTF-8"
        end
      end
    end


    context "with valid non UTF-8 source encoding" do

      it "should encode to UTF-8" do
        codec = LogStash::Codecs::Multiline.new("charset" => "ISO-8859-1", "pattern" => "^\\s", "what" => "previous")
        samples = [
          ["foobar", "foobar"],
          ["\xE0 Montr\xE9al", "à Montréal"],
        ]

        # lines = [ "foo \xED\xB9\x81\xC3", "bar \xAD" ]
        events = []
        samples.map{|(a, b)| a.force_encoding("ISO-8859-1")}.each do |line|
          insist { line.encoding.name } == "ISO-8859-1"
          insist { line.valid_encoding? } == true

          codec.decode(line) { |event| events << event }
        end
        codec.flush { |e| events << e }
        insist { events.size } == 2

        events.zip(samples.map{|(a, b)| b}).each do |tuple|
          insist { tuple[1].encoding.name } == "UTF-8"
          insist { tuple[0]["message"] } == tuple[1]
          insist { tuple[0]["message"].encoding.name } == "UTF-8"
        end
      end
    end

    context "with invalid non UTF-8 source encoding" do

     it "should encode to UTF-8" do
        codec = LogStash::Codecs::Multiline.new("charset" => "ASCII-8BIT", "pattern" => "^\\s", "what" => "previous")
        samples = [
          ["\xE0 Montr\xE9al", "� Montr�al"],
          ["\xCE\xBA\xCF\x8C\xCF\x83\xCE\xBC\xCE\xB5", "����������"],
        ]
        events = []
        samples.map{|(a, b)| a.force_encoding("ASCII-8BIT")}.each do |line|
          insist { line.encoding.name } == "ASCII-8BIT"
          insist { line.valid_encoding? } == true

          codec.decode(line) { |event| events << event }
        end
        codec.flush { |e| events << e }
        insist { events.size } == 2

        events.zip(samples.map{|(a, b)| b}).each do |tuple|
          insist { tuple[1].encoding.name } == "UTF-8"
          insist { tuple[0]["message"] } == tuple[1]
          insist { tuple[0]["message"].encoding.name } == "UTF-8"
        end
      end

    end
  end
end
