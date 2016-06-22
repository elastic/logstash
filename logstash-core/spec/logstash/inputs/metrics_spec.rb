# encoding: utf-8
require "logstash/inputs/metrics"
require "spec_helper"

describe LogStash::Inputs::Metrics do
  let(:collector) { LogStash::Instrument::Collector.new }
  let(:metric) { LogStash::Instrument::Metric.new(collector) }
  let(:queue) { [] }

  before :each do
    subject.metric = metric
  end

  describe "#run" do
    it "should register itself to the collector observer" do
      expect(collector).to receive(:add_observer).with(subject)
      t = Thread.new { subject.run(queue) }
      sleep(0.1) # give a bit of time to the thread to start
      subject.stop
    end
  end

  describe "#update" do
    it "should fill up the queue with received events" do
      Thread.new { subject.run(queue) }
      sleep(0.1)
      subject.stop

      metric.increment([:root, :test], :plugin)

      subject.update(collector.snapshot_metric)
      expect(queue.count).to eq(1)
    end
  end

  describe "#stop" do
    it "should remove itself from the the collector observer" do
      expect(collector).to receive(:delete_observer).with(subject)
      t = Thread.new { subject.run(queue) }
      sleep(0.1) # give a bit of time to the thread to start
      subject.stop
    end

    it "should unblock the input" do
      t = Thread.new { subject.run(queue) }
      sleep(0.1) # give a bit of time to the thread to start
      subject.do_stop
      wait_for { t.status }.to be_falsey
    end
  end
end
