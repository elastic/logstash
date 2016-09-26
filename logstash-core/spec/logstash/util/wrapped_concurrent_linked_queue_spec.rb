# encoding: utf-8
require "spec_helper"
require "logstash/util/wrapped_concurrent_linked_queue"

describe LogStash::Util::WrappedConcurrentLinkedQueue do
  context "#push" do
    it "returns true" do
      expect(subject.push("Bonjour")).to be(true)
    end
  end

  context "#pop" do
    context "when queue is empty" do
      it "returns null" do
        expect(subject.pop).to be_nil
      end
    end

    context "when queue has elements" do
      let(:element) { "Hello World!" }

      before do
        subject.push(element)
      end

      it "returns an element" do
        expect(subject.pop).to eq(element)
      end
    end
  end
end
