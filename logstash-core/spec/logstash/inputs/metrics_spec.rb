# encoding: utf-8
require "logstash/inputs/metrics"
require "spec_helper"

describe LogStash::Inputs::Metrics do
  let(:queue) { [] }

  describe "#run" do
    it "should register itself to the collector observer" do
      expect(LogStash::Instrument::Collector.instance).to receive(:add_observer).with(subject)
      t = Thread.new { subject.run(queue) }
      sleep(0.1) # give a bit of time to the thread to start
      subject.stop
    end
  end

  describe "#stop" do
    it "should remove itself from the the collector observer" do
      expect(LogStash::Instrument::Collector.instance).to receive(:delete_observer).with(subject)
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
