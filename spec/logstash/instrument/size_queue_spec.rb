# encoding: utf-8
require "logstash/instrument/size_queue"
require "logstash/instrument/metric"
require "logstash/event"
require "spec_helper"
require "thread"

describe LogStash::Instrument::SizeQueue do
  let(:event) { LogStash::Event.new }
  let(:collector) { [] }
  let(:queue) { Queue.new }
  let(:metric) { LogStash::Instrument::Metric.new(collector, "size_queue") }

  subject { LogStash::Instrument::SizeQueue.new(queue, metric) }

  context "collecting metrics" do
    context "#push" do

      [:push, :<<, :enq].each do |method|
        it "collect metric when calling #{method}" do
          subject.send(method, event)
          expect(collector.pop).to be_a_metric_event(:counter_increment, "size_queue-in", 1)
        end
      end
    end

    context "#pop" do
      before(:each) { queue.push(event) }

      [:pop, :shift, :deq].each do |method|
        it "collect metric when calling #{method}" do
          subject.send(method)
          expect(collector.pop).to be_a_metric_event(:counter_increment, "size_queue-out", 1)
        end
      end
    end
  end

  context "delegating methods to the the original queue" do
    [:clear, :size, :empty?, :length, :num_waiting].each do |method|
      it "#{method} calls the proxied instance" do
        expect(queue).to receive(method)
        subject.send(method)
      end
    end
  end
end
