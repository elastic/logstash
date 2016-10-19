require "logstash/util/byte_value"
require "flores/random"

describe LogStash::Util::ByteValue do
  let(:multipliers) do
    {
      "b" => 1,
      "kb" => 1 << 10,
      "mb" => 1 << 20,
      "gb" => 1 << 30,
      "tb" => 1 << 40,
      "pb" => 1 << 50,
    }
  end

  let(:number) { Flores::Random.number(0..100000000000) }
  let(:unit) { Flores::Random.item(multipliers.keys) }
  let(:text) { "#{number}#{unit}" }

  describe "#parse" do
    # Expect a whole-unit byte value. Fractions of a byte don't make sense here. :)
    let(:expected) { (number * multipliers[unit]).to_i }
    subject { described_class.parse(text) }

    it "should return a Numeric" do
      expect(subject).to be_a(Numeric)
    end

    it "should have an expected byte value" do
      expect(subject).to be == expected
    end
  end
end
