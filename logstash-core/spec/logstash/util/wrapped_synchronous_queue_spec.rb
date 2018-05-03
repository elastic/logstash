# encoding: utf-8
require "spec_helper"
require "logstash/instrument/collector"

describe LogStash::WrappedSynchronousQueue do

  subject {LogStash::WrappedSynchronousQueue.new(5)}

  describe "queue clients" do
    context "when requesting a write client" do
      it "returns a client" do
        expect(subject.write_client).to be_a(LogStash::MemoryWriteClient)
      end
    end

    context "when requesting a read client" do
      it "returns a client" do
        expect(subject.read_client).to be_a(LogStash::MemoryReadClient)
      end
    end

    describe "WriteClient | ReadClient" do
      let(:write_client) { subject.write_client }
      let(:read_client)  { subject.read_client }

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
            batch = []
            5.times {|i| batch.push(LogStash::Event.new({"message" => "value-#{i}"}))}
            write_client.push_batch(batch)

            read_batch = read_client.read_batch.to_java
            sleep(0.1) # simulate some work for the `duration_in_millis`
            # TODO: this interaction should be cleaned in an upcoming PR,
            # This is what the current pipeline does.
            read_client.add_filtered_metrics(read_batch.filteredSize)
            read_client.add_output_metrics(read_batch.filteredSize)
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
          read_client.set_events_metric(LogStash::Instrument::NamespacedNullMetric.new(nil, :null))
          read_client.set_pipeline_metric(LogStash::Instrument::NamespacedNullMetric.new(nil, :null))
        end

        it "appends batches to the queue" do
          batch = []
          messages = []
          5.times do |i|
            message = "value-#{i}"
            batch.push(LogStash::Event.new({"message" => message}))
            messages << message
          end
          write_client.push_batch(batch)
          read_batch = read_client.read_batch.to_java
          expect(read_batch.filteredSize).to eq(5)
          read_batch.to_a.each do |data|
            message = data.get("message")
            expect(messages).to include(message)
            messages.delete(message)
            # read_batch.cancel("value-#{i}") if i > 2     # TODO: disabled for https://github.com/elastic/logstash/issues/6055 - will have to properly refactor
            if message.match /value-[3-4]/
              data.cancel
              read_batch.merge(LogStash::Event.new({ "message" => message.gsub(/value/, 'generated') }))
            end
          end
          # expect(read_batch.cancelled_size).to eq(2) # disabled for https://github.com/elastic/logstash/issues/6055
          received = []
          read_batch.to_a.each do |data|
            received << data.get("message")
          end
          (0..2).each {|i| expect(received).to include("value-#{i}")}
          (3..4).each {|i| expect(received).to include("generated-#{i}")}
        end
      end
    end
  end
end
