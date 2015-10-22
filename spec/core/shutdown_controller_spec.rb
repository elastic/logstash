# encoding: utf-8
require "spec_helper"
require "logstash/shutdown_controller"

describe LogStash::ShutdownController do

  subject { LogStash::ShutdownController.new(pipeline) }
  let(:num_reports) { LogStash::ShutdownController::NUM_REPORTS }
  let(:pipeline) { double("pipeline") }

  before :each do
    LogStash::ShutdownController::REPORTS.clear
    allow(LogStash::DeadLetterPostOffice).to receive(:post)
    allow(pipeline).to receive(:dump) { [] }
    allow(pipeline).to receive(:force_exit)
    allow(pipeline).to receive(:inflight_count) do
      subject.stop! if return_values.empty?
      { "total" => (return_values.shift || 0) }
    end
  end

  after :each do
    subject.stop!
  end

  context "when force_shutdown is true" do

    before :each do
      subject.class.force_shutdown = true
    end

    context "with a non-stalled pipeline" do
      let(:return_values) { [8,7,6,5,4,3,2,1] }

      it "should request more than NUM_REPORTS \"inflight_count\"" do
        expect(pipeline).to receive(:inflight_count).at_least(num_reports + 1).times
        subject.start(0).join
      end

      it "shouldn't force exit after NUM_REPORTS cycles" do
        expect(pipeline).to_not receive(:force_exit)
        subject.start(0).join
      end

      it "shouldn't dump the pipeline" do
        expect(pipeline).to_not receive(:dump)
        subject.start(0).join
      end
    end

    context "with a stalled pipeline" do
      let(:return_values) { [5,5,6,6,6,6,6] }

      it "should force exit after NUM_REPORTS cycles" do
        expect(pipeline).to receive(:force_exit).once 
        subject.start(0).join
      end

      it "should dump all contents " do
        expect(pipeline).to receive(:dump).once
        subject.start(0).join
      end

      it "should post pipeline contents to DeadLetterPostOffice" do
        stalled_events = [LogStash::Event.new("message" => "test")]*2
        allow(pipeline).to receive(:dump) { stalled_events }
        expect(LogStash::DeadLetterPostOffice).to receive(:post).twice
        subject.start(0).join
      end
    end
  end
end
