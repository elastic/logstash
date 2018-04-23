# encoding: utf-8
require "logstash/instrument/periodic_poller/base"
require "logstash/instrument/collector"

describe LogStash::Instrument::PeriodicPoller::Base do
  let(:metric) { LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new) }
  let(:options) { {} }

  subject { described_class.new(metric, options) }

  describe "#update" do
    it "logs an timeout exception to debug level" do
      exception = Concurrent::TimeoutError.new
      expect(subject.logger).to receive(:debug).with(anything, hash_including(:exception => exception.class))
      subject.update(Time.now, "hola", exception)
    end

    it "logs any other exception to error level" do
      exception = Class.new
      expect(subject.logger).to receive(:error).with(anything, hash_including(:exception => exception.class))
      subject.update(Time.now, "hola", exception)
    end

    it "doesnt log anything when no exception is received" do
      exception = Concurrent::TimeoutError.new
      expect(subject.logger).not_to receive(:debug).with(anything)
      expect(subject.logger).not_to receive(:error).with(anything)
      subject.update(Time.now, "hola", exception)
    end
  end
end
