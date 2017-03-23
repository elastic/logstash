# encoding: utf-8
require "logstash/instrument/metric"
require "logstash/instrument/wrapped_write_client"
require "logstash/util/wrapped_synchronous_queue"
require "logstash/event"
require_relative "../../support/mocks_classes"
require "spec_helper"

describe LogStash::Instrument::WrappedWriteClient do
  let(:write_client) { queue.write_client }
  let(:read_client) { queue.read_client }
  let(:pipeline) { double("pipeline", :pipeline_id => :main) }
  let(:collector)   { LogStash::Instrument::Collector.new }
  let(:metric) { LogStash::Instrument::Metric.new(collector) }
  let(:plugin) { LogStash::Inputs::DummyInput.new({ "id" => myid }) }
  let(:event) { LogStash::Event.new }
  let(:myid) { "1234myid" }

  subject { described_class.new(write_client, pipeline, metric, plugin) }


  shared_examples "queue tests" do
    it "pushes single event to the `WriteClient`" do
      t = Thread.new do
        subject.push(event)
      end
      sleep(0.01) while !t.status
      expect(read_client.read_batch.size).to eq(1)
      t.kill rescue nil
    end

    it "pushes batch to the `WriteClient`" do
      batch = write_client.get_new_batch
      batch << event

      t = Thread.new do
        subject.push_batch(batch)
      end

      sleep(0.01) while !t.status
      expect(read_client.read_batch.size).to eq(1)
      t.kill rescue nil
    end

    context "recorded metrics" do
      before do
        t = Thread.new do
          subject.push(event)
        end
        sleep(0.01) while !t.status
        sleep(0.250) # make it block for some time, so duration isn't 0
        read_client.read_batch.size
        t.kill rescue nil
      end

      let(:snapshot_store) { collector.snapshot_metric.metric_store }

      let(:snapshot_metric) { snapshot_store.get_shallow(:stats) }

      it "records instance level events `in`" do
        expect(snapshot_metric[:events][:in].value).to eq(1)
      end

      it "records pipeline level `in`" do
        expect(snapshot_metric[:pipelines][:main][:events][:in].value).to eq(1)
      end

      it "record input `out`" do
        expect(snapshot_metric[:pipelines][:main][:plugins][:inputs][myid.to_sym][:events][:out].value).to eq(1)
      end

      context "recording of the duration of pushing to the queue" do
        it "records at the `global events` level" do
          expect(snapshot_metric[:events][:queue_push_duration_in_millis].value).to be_kind_of(Integer)
        end

        it "records at the `pipeline` level" do
          expect(snapshot_metric[:pipelines][:main][:events][:queue_push_duration_in_millis].value).to be_kind_of(Integer)
        end

        it "records at the `plugin level" do
          expect(snapshot_metric[:pipelines][:main][:plugins][:inputs][myid.to_sym][:events][:queue_push_duration_in_millis].value).to be_kind_of(Integer)
        end
      end
    end
  end

  context "WrappedSynchronousQueue" do
    let(:queue) { LogStash::Util::WrappedSynchronousQueue.new }

    before do
      read_client.set_events_metric(metric.namespace([:stats, :events]))
      read_client.set_pipeline_metric(metric.namespace([:stats, :pipelines, :main, :events]))
    end

    include_examples "queue tests"
  end

  context "AckedMemoryQueue" do
    let(:queue) { LogStash::Util::WrappedAckedQueue.create_memory_based("", 1024, 10, 1024) }

    before do
      read_client.set_events_metric(metric.namespace([:stats, :events]))
      read_client.set_pipeline_metric(metric.namespace([:stats, :pipelines, :main, :events]))
    end

    after do
      queue.close
    end

    include_examples "queue tests"
  end
end
