# encoding: utf-8
require "spec_helper"
require "logstash/shutdown_controller"

describe LogStash::ShutdownController do

  let(:check_every) { 0.01 }
  let(:check_threshold) { 100 }
  subject { LogStash::ShutdownController.new(pipeline, Thread.current, check_every) }
  let(:pipeline) { double("pipeline") }
  report_count = 0

  before :each do
    allow(LogStash::Report).to receive(:from_pipeline).and_wrap_original do |m, *args|
      report_count += 1
      m.call(*args)
    end
  end

  after :each do
    report_count = 0
  end

  context "when pipeline is stalled" do
    let(:increasing_count) { (1..5000).to_a.map {|i| { "total" => i } } }
    before :each do
      allow(pipeline).to receive(:inflight_count).and_return(*increasing_count)
      allow(pipeline).to receive(:stalling_threads) { { } }
    end

    describe ".unsafe_shutdown = true" do
      let(:abort_threshold) { subject.abort_threshold }
      let(:report_every) { subject.report_every }

      before :each do
        subject.class.unsafe_shutdown = true
      end

      it "should force the shutdown" do
        expect(subject).to receive(:force_exit).once
        subject.start
      end

      it "should do exactly \"abort_threshold\" stall checks" do
        allow(subject).to receive(:force_exit)
        expect(subject).to receive(:shutdown_stalled?).exactly(abort_threshold).times.and_call_original
        subject.start
      end

      it "should do exactly \"abort_threshold\"*\"report_every\" stall checks" do
        allow(subject).to receive(:force_exit)
        expect(LogStash::Report).to receive(:from_pipeline).exactly(abort_threshold*report_every).times.and_call_original
        subject.start
      end
    end

    describe ".unsafe_shutdown = false" do

      before :each do
        subject.class.unsafe_shutdown = false
      end

      it "shouldn't force the shutdown" do
        expect(subject).to_not receive(:force_exit)
        thread = Thread.new(subject) {|subject| subject.start }
        sleep 0.1 until report_count > check_threshold
        thread.kill
      end
    end
  end

  context "when pipeline is not stalled" do
    let(:decreasing_count) { (1..5000).to_a.reverse.map {|i| { "total" => i } } }
    before :each do
      allow(pipeline).to receive(:inflight_count).and_return(*decreasing_count)
      allow(pipeline).to receive(:stalling_threads) { { } }
    end

    describe ".unsafe_shutdown = true" do

      before :each do
        subject.class.unsafe_shutdown = true
      end

      it "should force the shutdown" do
        expect(subject).to_not receive(:force_exit)
        thread = Thread.new(subject) {|subject| subject.start }
        sleep 0.1 until report_count > check_threshold
        thread.kill
      end
    end

    describe ".unsafe_shutdown = false" do

      before :each do
        subject.class.unsafe_shutdown = false
      end

      it "shouldn't force the shutdown" do
        expect(subject).to_not receive(:force_exit)
        thread = Thread.new(subject) {|subject| subject.start }
        sleep 0.1 until report_count > check_threshold
        thread.kill
      end
    end
  end
end
