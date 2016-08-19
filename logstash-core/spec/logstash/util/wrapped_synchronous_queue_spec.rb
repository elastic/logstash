# encoding: utf-8
require "spec_helper"
require "logstash/util/wrapped_synchronous_queue"

describe LogStash::Util::WrappedSynchronousQueue do
  context "#offer" do
    context "queue is blocked" do
      it "fails and give feedback" do
        expect(subject.offer("Bonjour", 2)).to be_falsey
      end
    end

    context "queue is not blocked" do
      before do
        @consumer = Thread.new { loop { subject.take } }
        sleep(0.1)
      end

      after do
        @consumer.kill
      end

      it "inserts successfully" do
        expect(subject.offer("Bonjour", 20)).to be_truthy
      end
    end
  end

  describe "queue clients" do
    context "when requesting a write client" do
      it "returns a client" do
        expect(subject.write_client).to be_a(LogStash::Util::WrappedSynchronousQueue::WriteClient)
      end
    end

    context "when requesting a read client" do
      it "returns a client" do
        expect(subject.read_client).to be_a(LogStash::Util::WrappedSynchronousQueue::ReadClient)
      end
    end

    class DummyQueue < Array
      def take() shift(); end
      def poll(*) shift(); end
    end

    describe "WriteClient | ReadClient" do
      context "when writing to the queue" do
        let(:queue) { DummyQueue.new }
        let(:write_client) { LogStash::Util::WrappedSynchronousQueue::WriteClient.new(queue)}
        let(:read_client)  { LogStash::Util::WrappedSynchronousQueue::ReadClient.new(queue)}

        before :each do
          read_client.set_events_metric(LogStash::Instrument::NullMetric.new)
          read_client.set_pipeline_metric(LogStash::Instrument::NullMetric.new)
        end

        it "appends batches to the queue" do
          batch = write_client.get_new_batch
          5.times {|i| batch.push("value-#{i}")}
          write_client.push_batch(batch)
          read_batch = read_client.take_batch
          expect(read_batch.size).to eq(5)
          i = 0
          read_batch.each do |data|
            expect(data).to eq("value-#{i}")
            read_batch.cancel("value-#{i}") if i > 2
            read_batch.merge("generated-#{i}") if i > 2
            i += 1
          end
          expect(read_batch.cancelled_size).to eq(2)
          i = 0
          read_batch.each do |data|
            expect(data).to eq("value-#{i}") if i < 3
            expect(data).to eq("generated-#{i}") if i > 2
            i += 1
          end
        end
      end
    end
  end
end
