# encoding: utf-8
require "spec_helper"

describe LogStash::ShutdownWatcher do
  let(:check_every) { 0.01 }
  let(:check_threshold) { 100 }
  subject { LogStash::ShutdownWatcher.new(pipeline, check_every) }
  let(:pipeline) { double("pipeline") }
  let(:reporter) { double("reporter") }
  let(:reporter_snapshot) { double("reporter snapshot") }

  before :each do
    allow(pipeline).to receive(:reporter).and_return(reporter)
    allow(pipeline).to receive(:thread).and_return(Thread.current)
    allow(reporter).to receive(:snapshot).and_return(reporter_snapshot)
    allow(reporter_snapshot).to receive(:o_simple_hash).and_return({})
  end

  context "when pipeline is stalled" do
    let(:increasing_count) { (1..5000).to_a }
    before :each do
      allow(reporter_snapshot).to receive(:inflight_count).and_return(*increasing_count)
      allow(reporter_snapshot).to receive(:stalling_threads) { { } }
    end

    describe ".unsafe_shutdown = false" do

      before :each do
        subject.class.unsafe_shutdown = false
      end

      it "shouldn't force the shutdown" do
        expect(subject).to_not receive(:force_exit)
        thread = Thread.new(subject) {|subject| subject.start }
        sleep 0.1 until subject.attempts_count > check_threshold
        subject.stop!
        expect(thread.join(60)).to_not be_nil
      end
    end
  end

  context "when pipeline is not stalled" do
    let(:decreasing_count) { (1..5000).to_a.reverse }
    before :each do
      allow(reporter_snapshot).to receive(:inflight_count).and_return(*decreasing_count)
      allow(reporter_snapshot).to receive(:stalling_threads) { { } }
    end

    describe ".unsafe_shutdown = true" do

      before :each do
        subject.class.unsafe_shutdown = true
      end

      it "should force the shutdown" do
        expect(subject).to_not receive(:force_exit)
        thread = Thread.new(subject) {|subject| subject.start }
        sleep 0.1 until subject.attempts_count > check_threshold
        subject.stop!
        expect(thread.join(60)).to_not be_nil
      end
    end

    describe ".unsafe_shutdown = false" do

      before :each do
        subject.class.unsafe_shutdown = false
      end

      it "shouldn't force the shutdown" do
        expect(subject).to_not receive(:force_exit)
        thread = Thread.new(subject) {|subject| subject.start }
        sleep 0.1 until subject.attempts_count > check_threshold
        subject.stop!
        thread.join
        expect(thread.join(60)).to_not be_nil
      end
    end
  end
end
