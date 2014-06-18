require "logstash/util"


describe LogStash::Util do

  context "stringify_keys" do
    it "should convert hash symbol keys to strings" do
      expect(LogStash::Util.stringify_symbols({:a => 1, "b" => 2})).to eq({"a" => 1, "b" => 2})
    end

    it "should keep non symbolic hash keys as is" do
      expect(LogStash::Util.stringify_symbols({1 => 1, 2.0 => 2})).to eq({1 => 1, 2.0 => 2})
    end

    it "should convert inner hash keys to strings" do
      expect(LogStash::Util.stringify_symbols({:a => 1, "b" => {:c => 3}})).to eq({"a" => 1, "b" => {"c" => 3}})
      expect(LogStash::Util.stringify_symbols([:a, 1, "b", {:c => 3}])).to eq(["a", 1, "b", {"c" => 3}])
    end

    it "should convert hash symbol values to strings" do
      expect(LogStash::Util.stringify_symbols({:a => :a, "b" => :b})).to eq({"a" => "a", "b" => "b"})
    end

    it "should convert array symbol values to strings" do
      expect(LogStash::Util.stringify_symbols([1, :a])).to eq([1, "a"])
    end

    it "should convert innner array symbol values to strings" do
      expect(LogStash::Util.stringify_symbols({:a => [1, :b]})).to eq({"a" => [1, "b"]})
      expect(LogStash::Util.stringify_symbols([:a, [1, :b]])).to eq(["a", [1, "b"]])
    end
  end
end
