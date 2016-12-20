# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Setting::Bytes do
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

  let(:number) { Flores::Random.number(0..1000) }
  let(:unit) { Flores::Random.item(multipliers.keys) }
  let(:default) { "0b" }

  subject { described_class.new("a byte value", default, false) }

  describe "#set" do

    # Hard-coded test just to make sure at least one known case is working
    context "when given '10mb'" do
      it "returns 10485760" do
        expect(subject.set("10mb")).to be == 10485760
      end
    end

    context "when given a string" do
      context "which is a valid byte unit" do
        let(:text) { "#{number}#{unit}" }

        before { subject.set(text) }

        it "should coerce it to a Fixnum" do
          expect(subject.value).to be_a(Fixnum)
        end
      end

      context "which is not a valid byte unit" do
        values = [ "hello world", "1234", "", "-__-" ]
        values.each do |value|
          it "should fail" do
            expect { subject.set(value) }.to raise_error
          end
        end
      end
    end
  end
end
