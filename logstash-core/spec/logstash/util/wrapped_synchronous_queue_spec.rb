# encoding: utf-8
require "spec_helper"
require "logstash/util/wrapped_synchronous_queue"
require "logstash/instrument/collector"

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
      let(:queue) { DummyQueue.new }
      let(:write_client) { LogStash::Util::WrappedSynchronousQueue::WriteClient.new(queue)}
      let(:read_client)  { LogStash::Util::WrappedSynchronousQueue::ReadClient.new(queue)}

      context "when reading from the queue" do
        let(:collector) { LogStash::Instrument::Collector.new }

        before do
          read_client.set_events_metric(LogStash::Instrument::Metric.new(collector).namespace(:events))
          read_client.set_pipeline_metric(LogStash::Instrument::Metric.new(collector).namespace(:pipeline))
        end

        context "when the queue is empty" do
          it "doesnt record the `duration_in_millis`" do
            batch = read_client.take_batch
            read_client.close_batch(batch)
            store = collector.snapshot_metric.metric_store
            expect(store.size).to eq(0)
          end
        end

        context "when we have item in the queue" do
          it "records the `duration_in_millis`" do
            batch = write_client.get_new_batch
            5.times {|i| batch.push("value-#{i}")}
            write_client.push_batch(batch)
            read_batch = read_client.take_batch
            sleep(0.1) # simulate some work?
            read_client.close_batch(batch)
            store = collector.snapshot_metric.metric_store

            expect(store.size).to eq(4)
            expect(store.get_shallow(:events, :in).value).to eq(5)
            expect(store.get_shallow(:events, :duration_in_millis).value).to be > 0
            expect(store.get_shallow(:pipeline, :in).value).to eq(5)
            expect(store.get_shallow(:pipeline, :duration_in_millis).value).to be > 0
          end
        end
      end

      context "when writing to the queue" do
        before :each do
          read_client.set_events_metric(LogStash::Instrument::NamespacedNullMetric.new([], :null))
          read_client.set_pipeline_metric(LogStash::Instrument::NamespacedNullMetric.new([], :null))
        end

        it "appends batches to the queue" do
          batch = write_client.get_new_batch
          5.times {|i| batch.push(LogStash::Event.new({"message" => "value-#{i}"}))}
          write_client.push_batch(batch)
          read_batch = read_client.take_batch
          expect(read_batch.size).to eq(5)
          i = 0
          read_batch.each do |data|
            expect(data.get("message")).to eq("value-#{i}")
            # read_batch.cancel("value-#{i}") if i > 2     # TODO: disabled for https://github.com/elastic/logstash/issues/6055 - will have to properly refactor
            data.cancel if i > 2
            read_batch.merge(LogStash::Event.new({"message" => "generated-#{i}"})) if i > 2
            i += 1
          end
          # expect(read_batch.cancelled_size).to eq(2) # disabled for https://github.com/elastic/logstash/issues/6055
          i = 0
          read_batch.each do |data|
            expect(data.get("message")).to eq("value-#{i}") if i < 3
            expect(data.get("message")).to eq("generated-#{i}") if i > 2
            i += 1
          end
        end
      end
    end
  end
end
