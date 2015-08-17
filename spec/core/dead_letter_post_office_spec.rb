# encoding: utf-8
require "spec_helper"

describe LogStash::DeadLetterPostOffice do

  describe ".<<" do
    subject { LogStash::DeadLetterPostOffice }
    let(:filter) { LogStash::Filter::Base.new }
    let(:event) { LogStash::Event.new("message" => "test") }
    let(:destination) { LogStash::DeadLetterPostOffice::Destination::Base.new }

    before :each do
      subject.destination = destination
      allow(destination).to receive(:<<) {|event|  }
    end

    it "should send event to destination" do
      expect(destination).to receive(:<<).with(event)
      subject << event
    end

    it "should tag the event with \"_dead_letter\"" do
      subject << event
      expect(event["tags"]).to include("_dead_letter")
    end

    it "should cancel the event" do
      subject << event
      expect(event).to be_cancelled
    end

    context "array of events" do
      let(:event1) { LogStash::Event.new("message" => "test1") }
      let(:event2) { LogStash::Event.new("message" => "test2") }
      let(:event3) { LogStash::Event.new("message" => "test3") }
      let(:events) { [event1, event2, event3] }

      it "should push each event to the destination" do
        expect(destination).to receive(:<<).with(event1)
        expect(destination).to receive(:<<).with(event2)
        expect(destination).to receive(:<<).with(event3)
        subject << events
      end
    end
  end
end
