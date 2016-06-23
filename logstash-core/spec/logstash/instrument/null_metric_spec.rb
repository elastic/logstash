# encoding: utf-8
require "logstash/instrument/null_metric"

describe LogStash::Instrument::NullMetric do
  let(:key) { "galaxy" }

  describe "#increment" do
    it "allows to increment a key with no amount" do
      expect { subject.increment(key, 100) }.not_to raise_error
    end

    it "allow to increment a key" do
      expect { subject.increment(key) }.not_to raise_error
    end
  end

  describe "#decrement" do
    it "allows to decrement a key with no amount" do
      expect { subject.decrement(key, 100) }.not_to raise_error
    end

    it "allow to decrement a key" do
      expect { subject.decrement(key) }.not_to raise_error
    end
  end

  describe "#gauge" do
    it "allows to set a value" do
      expect { subject.gauge(key, "pluto") }.not_to raise_error
    end
  end

  describe "#report_time" do
    it "allow to record time" do
      expect { subject.report_time(key, 1000) }.not_to raise_error
    end
  end

  describe "#time" do
    it "allow to record time with a block given" do
      expect do
        subject.time(key) { 1+1 }
      end.not_to raise_error
    end

    it "when using a block it return the generated value" do
      expect(subject.time(key) { 1+1 }).to eq(2)
    end

    it "allow to record time with no block given" do
      expect do
        clock = subject.time(key)
        clock.stop
      end.not_to raise_error
    end
  end

  describe "#namespace" do
    it "return a NullMetric" do
      expect(subject.namespace(key)).to be_kind_of LogStash::Instrument::NullMetric
    end
  end
end
