# encoding: utf-8
require "logstash/json"
require "logstash/environment"
require "logstash/util"

describe LogStash::Json do

  let(:hash)   {{"a" => 1}}
  let(:json_hash)   {"{\"a\":1}"}

  let(:string) {"foobar"}
  let(:json_string) {"\"foobar\""}

  let(:array)  {["foo", "bar"]}
  let(:json_array)  {"[\"foo\",\"bar\"]"}

  let(:multi) {
    [
      {:ruby => "foo bar baz", :json => "\"foo bar baz\""},
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

  if LogStash::Environment.jruby?

    ### JRuby specific

    context "jruby deserialize" do
      it "should respond to load and deserialize object" do
        expect(JrJackson::Raw).to receive(:parse_raw).with(json_hash).and_call_original
        expect(LogStash::Json.load(json_hash)).to eql(hash)
      end
    end

    context "jruby serialize" do
      it "should respond to dump and serialize object" do
        expect(JrJackson::Json).to receive(:dump).with(string).and_call_original
        expect(LogStash::Json.dump(string)).to eql(json_string)
      end

      it "should call JrJackson::Raw.generate for Hash" do
        expect(JrJackson::Raw).to receive(:generate).with(hash).and_call_original
        expect(LogStash::Json.dump(hash)).to eql(json_hash)
      end

      it "should call JrJackson::Raw.generate for Array" do
        expect(JrJackson::Raw).to receive(:generate).with(array).and_call_original
        expect(LogStash::Json.dump(array)).to eql(json_array)
      end
    end
  else

    ### MRI specific

    it "should respond to load and deserialize object on mri" do
      expect(Oj).to receive(:load).with(json).and_call_original
      expect(LogStash::Json.load(json)).to eql(hash)
    end

    it "should respond to dump and serialize object on mri" do
      expect(Oj).to receive(:dump).with(hash, anything).and_call_original
      expect(LogStash::Json.dump(hash)).to eql(json)
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
    expect{LogStash::Json.load("abc")}.to raise_error LogStash::Json::ParserError
  end
end
