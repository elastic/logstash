# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "spec_helper"
require "logstash/json"
require "logstash/environment"
require "logstash/util"

describe "LogStash::Json" do
  let(:hash)   {{"a" => 1}}
  let(:json_hash)   {"{\"a\":1}"}

  let(:string) {"foobar"}
  let(:json_string) {"\"foobar\""}

  let(:array)  {["foo", "bar"]}
  let(:json_array)  {"[\"foo\",\"bar\"]"}

  let(:multi) {
    [
      {:ruby => "foo bar baz", :json => "\"foo bar baz\""},
      {:ruby => "foo   ", :json => "\"foo   \""},
      {:ruby => " ", :json => "\" \""},
      {:ruby => "   ", :json => "\"   \""},
      {:ruby => "1", :json => "\"1\""},
      {:ruby => {"a" => true}, :json => "{\"a\":true}"},
      {:ruby => {"a" => nil}, :json => "{\"a\":null}"},
      {:ruby => ["a", "b"], :json => "[\"a\",\"b\"]"},
      {:ruby => [1, 2], :json => "[1,2]"},
      {:ruby => [1, nil], :json => "[1,null]"},
      {:ruby => {"a" => [1, 2]}, :json => "{\"a\":[1,2]}"},
      {:ruby => {"a" => {"b" => 2}}, :json => "{\"a\":{\"b\":2}}"},
      # {:ruby => , :json => },
    ]
  }

  # Former expectation in this code were removed because of https://github.com/rspec/rspec-mocks/issues/964
  # as soon as is fix we can re introduce them if desired, however for now the completeness of the test
  # is also not affected as the conversion would not work if the expectation where not meet.
  ###
  context "jruby deserialize" do
    it "should respond to load and deserialize object" do
      expect(LogStash::Json.load(json_hash)).to eql(hash)
    end
  end

  context "jruby serialize" do
    it "should respond to dump and serialize object" do
      expect(LogStash::Json.dump(string)).to eql(json_string)
    end

    it "should call JrJackson::Raw.generate for Hash" do
      expect(LogStash::Json.dump(hash)).to eql(json_hash)
    end

    it "should call JrJackson::Raw.generate for Array" do
      expect(LogStash::Json.dump(array)).to eql(json_array)
    end

    context "pretty print" do
      let(:hash) { { "foo" => "bar", :zoo => 2 } }

      it "should serialize with pretty print" do
        pprint_json = LogStash::Json.dump(hash, :pretty => true)
        expect(pprint_json).to include("\n")
      end

      it "should by default do no pretty print" do
        pprint_json = LogStash::Json.dump(hash)
        expect(pprint_json).not_to include("\n")
      end
    end
  end

  ### non specific

  it "should correctly deserialize" do
    multi.each do |test|
      # because JrJackson in :raw mode uses Java::JavaUtil::LinkedHashMap and
      # Java::JavaUtil::ArrayList, we must cast to compare.
      # other than that, they quack like their Ruby equivalent
      expect(LogStash::Util.normalize(LogStash::Json.load(test[:json]))).to eql(test[:ruby])
    end
  end

  it "should correctly serialize" do
    multi.each do |test|
      expect(LogStash::Json.dump(test[:ruby])).to eql(test[:json])
    end
  end

  it "should raise Json::ParserError on invalid json" do
    expect {LogStash::Json.load("abc")}.to raise_error LogStash::Json::ParserError
  end

  it "should return nil on empty string" do
    o = LogStash::Json.load("")
    expect(o).to be_nil
  end

  it "should return nil on blank string" do
    o = LogStash::Json.load(" ")
    expect(o).to be_nil
    o = LogStash::Json.load("  ")
    expect(o).to be_nil
  end

  # a safeguard guard test to ensure that Json#dump does not break (especially if internally processes)
  # current behavior when Event (RubyEvent object) is passed
  describe "Json#dump the event" do
    let(:sample_count) { 10 }
    let(:sample_event) { LogStash::Event.new('message' => 'This is a message') }
    let(:dumped_sample_event) { LogStash::Json.dump(sample_event) }
    let(:sample_events) do
      sample_count.times.map do
        [sample_event, dumped_sample_event]
      end
    end

    it 'validates the Json#dump event' do
      sample_events.each do |sample_event, dumped_sample_event|
        # Json#dump internally normalizes Event as it is
        expect(sample_event.to_json).to eql(dumped_sample_event)
      end
    end
  end

  context "Unicode edge-cases" do
    matcher :be_utf8 do
      match(:notify_expectation_failures => true) do |actual|
        aggregate_failures do
          expect(actual).to have_attributes(:encoding => Encoding::UTF_8, :valid_encoding? => true)
          expect(actual.bytes).to eq(@expected_bytes) unless @expected_bytes.nil?
        end
      end
      chain :with_bytes do |expected_bytes|
        @expected_bytes = expected_bytes
      end
    end

    let(:result) { LogStash::Json::dump(input) }

    context "with valid non-unicode encoding" do
      let(:input) { "Th\xEFs \xCCs W\xCFnd\xD8w\x8A".b.force_encoding(Encoding::WINDOWS_1252).freeze }
      it 'transcodes to equivalent UTF-8 code-points' do
        aggregate_failures do
          expect(result).to be_utf8.with_bytes("\u{22}Th\u{EF}s \u{CC}s W\u{CF}nd\u{D8}w\u{160}\u{22}".bytes)
        end
      end
    end

    context "with unicode that has invalid sequences" do
      let(:input) { "Thïs is a not-quite-v\xCEalid uni\xF0\x9D\x84code string 💖ok".b.force_encoding(Encoding::UTF_8).freeze }
      it 'replaces each invalid sequence with the xFFFD replacement character' do
        expect(result).to be_utf8.with_bytes("\x22Thïs is a not-quite-v\u{FFFD}alid uni\u{FFFD}code string 💖ok\x22".bytes)
      end
    end

    context 'with valid unicode' do
      let(:input) { "valid \u{A7}\u{a9c5}\u{18a5}\u{1f984} unicode".encode('UTF-8').freeze }
      it 'keeps the unicode in-tact' do
        expect(result).to be_utf8.with_bytes(('"' + input + '"').bytes)
      end
    end

    context 'with binary-flagged input' do

      context 'that contains only lower-ascii' do
        let(:input) { "hello, world. This is a test including newline(\x0A) literal-backslash(\x5C) double-quote(\x22)".b.force_encoding(Encoding::BINARY).freeze}
        it 'does not munge the bytes' do
          expect(result).to be_utf8.with_bytes("\x22hello, world. This is a test including newline(\x5Cn) literal-backslash(\x5C\x5C) double-quote(\x5C\x22)\x22".bytes)
        end
      end

      context 'that contains bytes outside lower-ascii' do
        let(:input) { "Thïs is a not-quite-v\xCEalid uni\xF0\x9D\x84code string 💖ok".b.force_encoding(Encoding::BINARY).freeze }
        it 'replaces each invalid sequence with the xFFFD replacement character' do
          expect(result).to be_utf8.with_bytes("\x22Thïs is a not-quite-v\u{FFFD}alid uni\u{FFFD}code string 💖ok\x22".bytes)
        end
      end

    end

    context 'with hash data structure' do
      let(:input) {{"Th\xEFs key and".b.force_encoding(Encoding::WINDOWS_1252).freeze =>
                      {"Thïs key also".b.force_encoding(Encoding::UTF_8).freeze => "not-quite-v\xCEalid uni\xF0\x9D\x84code string 💖ok".b.force_encoding(Encoding::UTF_8).freeze}}}
      it 'normalizes and replaces each invalid key-value with the xFFFD replacement character' do
        expect(result).to be_utf8.with_bytes("{\"Th\u{EF}s key and\":{\"Thïs key also\":\"not-quite-v\u{FFFD}alid uni\u{FFFD}code string 💖ok\"}}".bytes)
      end
    end

    context 'with array data structure' do
      let(:input) {["Th\xEFs entry and".b.force_encoding(Encoding::WINDOWS_1252).freeze,
                    "Thïs entry also".b.force_encoding(Encoding::UTF_8).freeze,
                    "not-quite-v\xCEalid uni\xF0\x9D\x84code strings 💖ok".b.force_encoding(Encoding::UTF_8).freeze]}
      it 'normalizes and replaces each invalid array values with the xFFFD replacement character' do
        expect(result).to be_utf8.with_bytes("[\"Th\u{EF}s entry and\",\"Thïs entry also\",\"not-quite-v\u{FFFD}alid uni\u{FFFD}code strings 💖ok\"]".bytes)
      end
    end
  end
end
