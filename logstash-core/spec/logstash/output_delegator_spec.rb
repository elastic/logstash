# encoding: utf-8
require 'spec_helper'

require "logstash/output_delegator"
describe LogStash::OutputDelegator do
  let(:logger) { double("logger") }
  let(:out_klass) { double("output klass") }
  let(:out_inst) { double("output instance") }

  subject { described_class.new(logger, out_klass) }

  before do
    allow(out_klass).to receive(:new).with(any_args).and_return(out_inst)
    allow(out_inst).to receive(:register)
    allow(logger).to receive(:debug).with(any_args)
  end

  it "should initialize cleanly" do
    expect { subject }.not_to raise_error
  end

  context "after having received a batch of events" do
    let(:events) { 7.times.map { LogStash::Event.new }}

    before do
      allow(out_inst).to receive(:multi_receive)
      subject.multi_receive(events)
    end

    it "should pass the events through" do
      expect(out_inst).to have_received(:multi_receive).with(events)
    end

    it "should increment the number of events received" do
      expect(subject.events_received).to eql(events.length)
    end
  end

  it "should register all workers on register" do
    expect(out_inst).to receive(:register)
    subject.register
  end

  it "should close all workers when closing" do
    expect(out_inst).to receive(:do_close)
    subject.do_close
  end
end
