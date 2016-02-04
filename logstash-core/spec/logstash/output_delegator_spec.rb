# encoding: utf-8
require "logstash/output_delegator"
require 'spec_helper'

describe LogStash::OutputDelegator do
  let(:logger) { double("logger") }
  let(:events) { 7.times.map { LogStash::Event.new }}
  let(:default_worker_count) { 1 }

  subject { described_class.new(logger, out_klass, default_worker_count, LogStash::Instrument::NullMetric.new) }

  context "with a plain output plugin" do
    let(:out_klass) { double("output klass") }
    let(:out_inst) { double("output instance") }

    before(:each) do
      allow(out_klass).to receive(:new).with(any_args).and_return(out_inst)
      allow(out_klass).to receive(:threadsafe?).and_return(false)
      allow(out_klass).to receive(:workers_not_supported?).and_return(false)
      allow(out_inst).to receive(:register)
      allow(out_inst).to receive(:multi_receive)
      allow(out_inst).to receive(:metric=).with(any_args)
      allow(out_inst).to receive(:id).and_return("a-simple-plugin")
      allow(logger).to receive(:debug).with(any_args)
    end

    it "should initialize cleanly" do
      expect { subject }.not_to raise_error
    end

    context "after having received a batch of events" do
      before do
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

    describe "concurrency and worker support" do
      describe "non-threadsafe outputs that allow workers" do
        let(:default_worker_count) { 3 }

        before do
          allow(out_klass).to receive(:threadsafe?).and_return(false)
          allow(out_klass).to receive(:workers_not_supported?).and_return(false)
          allow(out_inst).to receive(:metric=).with(any_args)
          allow(out_inst).to receive(:id).and_return("a-simple-plugin")
        end

        it "should instantiate multiple workers" do
          expect(subject.workers.length).to eql(default_worker_count)
        end

        it "should send received events to the worker" do
          expect(out_inst).to receive(:multi_receive).with(events)
          subject.multi_receive(events)
        end
      end

      describe "threadsafe outputs" do
        before do
          allow(out_klass).to receive(:threadsafe?).and_return(true)
          allow(out_inst).to receive(:metric=).with(any_args)
          allow(out_inst).to receive(:id).and_return("a-simple-plugin")
          allow(out_klass).to receive(:workers_not_supported?).and_return(false)
        end

        it "should return true when threadsafe? is invoked" do
          expect(subject.threadsafe?).to eql(true)
        end

        it "should define a threadsafe_worker" do
          expect(subject.send(:threadsafe_worker)).to eql(out_inst)
        end

        it "should utilize threadsafe_multi_receive" do
          expect(subject.send(:threadsafe_worker)).to receive(:multi_receive).with(events)
          subject.multi_receive(events)
        end

        it "should not utilize the worker queue" do
          expect(subject.send(:worker_queue)).not_to receive(:pop)
          subject.multi_receive(events)
        end

        it "should send received events to the worker" do
          expect(out_inst).to receive(:multi_receive).with(events)
          subject.multi_receive(events)
        end
      end
    end
  end

  # This may seem suspiciously similar to the class in outputs/base_spec
  # but, in fact, we need a whole new class because using this even once
  # will immutably modify the base class
  class LogStash::Outputs::NOOPDelLegacyNoWorkers < ::LogStash::Outputs::Base
    LEGACY_WORKERS_NOT_SUPPORTED_REASON = "legacy reason"

    def register
      workers_not_supported(LEGACY_WORKERS_NOT_SUPPORTED_REASON)
    end
  end

  describe "legacy output workers_not_supported" do
    let(:default_worker_count) { 2 }
    let(:out_klass) { LogStash::Outputs::NOOPDelLegacyNoWorkers }

    before do
      allow(logger).to receive(:debug).with(any_args)
    end

    it "should only setup one worker" do
      expect(subject.worker_count).to eql(1)
    end
  end
end
