# encoding: utf-8
require "spec_helper"
require "logstash/util/wrapped_synchronous_queue"
require "logstash/instrument/collector"

describe LogStash::Util::WrappedSynchronousQueue do

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
            batch = read_client.read_batch
            read_client.close_batch(batch)
            store = collector.snapshot_metric.metric_store

            expect(store.get_shallow(:events, :out).value).to eq(0)
            expect(store.get_shallow(:events, :out)).to be_kind_of(LogStash::Instrument::MetricType::Counter)

            expect(store.get_shallow(:events, :filtered).value).to eq(0)
            expect(store.get_shallow(:events, :filtered)).to be_kind_of(LogStash::Instrument::MetricType::Counter)

            expect(store.get_shallow(:events, :duration_in_millis).value).to eq(0)
            expect(store.get_shallow(:events, :duration_in_millis)).to be_kind_of(LogStash::Instrument::MetricType::Counter)

            expect(store.get_shallow(:pipeline, :duration_in_millis).value).to eq(0)
            expect(store.get_shallow(:pipeline, :duration_in_millis)).to be_kind_of(LogStash::Instrument::MetricType::Counter)

            expect(store.get_shallow(:pipeline, :out).value).to eq(0)
            expect(store.get_shallow(:pipeline, :out)).to be_kind_of(LogStash::Instrument::MetricType::Counter)

            expect(store.get_shallow(:pipeline, :filtered).value).to eq(0)
            expect(store.get_shallow(:pipeline, :filtered)).to be_kind_of(LogStash::Instrument::MetricType::Counter)
          end
        end

        context "when we have item in the queue" do
          it "records the `duration_in_millis`" do
            batch = write_client.get_new_batch
            5.times {|i| batch.push("value-#{i}")}
            write_client.push_batch(batch)

            read_batch = read_client.read_batch
            sleep(0.1) # simulate some work for the `duration_in_millis`
            # TODO: this interaction should be cleaned in an upcoming PR,
            # This is what the current pipeline does.
            read_client.add_filtered_metrics(read_batch)
            read_client.add_output_metrics(read_batch)
            read_client.close_batch(read_batch)
            store = collector.snapshot_metric.metric_store

            expect(store.get_shallow(:events, :out).value).to eq(5)
            expect(store.get_shallow(:events, :filtered).value).to eq(5)
            expect(store.get_shallow(:events, :duration_in_millis).value).to be > 0
            expect(store.get_shallow(:pipeline, :duration_in_millis).value).to be > 0
            expect(store.get_shallow(:pipeline, :out).value).to eq(5)
            expect(store.get_shallow(:pipeline, :filtered).value).to eq(5)
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
          read_batch = read_client.read_batch
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
