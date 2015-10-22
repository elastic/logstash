# encoding: utf-8
require "spec_helper"

describe LogStash::DeadLetterPostOffice do

  describe ".post" do
    subject { LogStash::DeadLetterPostOffice }
    let(:filter) { LogStash::Filter::Base.new }
    let(:event) { LogStash::Event.new("message" => "test") }
    let(:destination) { LogStash::DeadLetterPostOffice::Destination::Base.new }

    before :each do
      subject.destination = destination
      allow(destination).to receive(:post) {|event|  }
    end

    it "should send event to destination" do
      expect(destination).to receive(:post).with(event)
      subject.post(event)
    end

    it "should tag the event with \"_dead_letter\"" do
      subject.post(event)
      expect(event["tags"]).to include("_dead_letter")
    end

    it "should cancel the event" do
      subject.post(event)
      expect(event).to be_cancelled
    end
  end
end
