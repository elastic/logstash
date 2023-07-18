# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require_relative "../../support/mocks_classes"
require "spec_helper"
require "java"

describe LogStash::WrappedWriteClient do
  let!(:write_client) { queue.write_client }
  let!(:read_client) { queue.read_client }
  let(:collector)   { LogStash::Instrument::Collector.new }
  let(:metric) { LogStash::Instrument::Metric.new(collector) }
  let(:event) { LogStash::Event.new }
  let(:myid) { ":1234myid".to_sym }

  subject { described_class.new(write_client, :main, metric, myid) }

  def threaded_read_client
    Thread.new do
      started_at = Time.now

      batch_size = 0
      loop {
        if Time.now - started_at > 60
          raise "Took too much time to read from the queue"
        end
        batch = read_client.read_batch.to_java
        batch_size = batch.filteredSize()

        break if batch_size > 0
      }
      expect(batch_size).to eq(1)
    end
  end

  shared_examples "queue tests" do
    it "pushes single event to the `WriteClient`" do
      pusher_thread = Thread.new(subject, event) do |_subject, _event|
        _subject.push(_event)
      end

      reader_thread = threaded_read_client

      [pusher_thread, reader_thread].collect(&:join)
    end

    it "pushes batch to the `WriteClient`" do
      batch = []
      batch << event

      pusher_thread = Thread.new(subject, batch) do |_subject, _batch|
        _subject.push_batch(_batch)
      end

      reader_thread = threaded_read_client
      [pusher_thread, reader_thread].collect(&:join)
    end

    context "recorded metrics" do
      before do
        pusher_thread = Thread.new(subject, event) do |_subject, _event|
          _subject.push(_event)
        end

        reader_thread = threaded_read_client
        [pusher_thread, reader_thread].collect(&:join)
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
        expect(snapshot_metric[:pipelines][:main][:plugins][:inputs][myid][:events][:out].value).to eq(1)
      end

      context "recording of the duration of pushing to the queue" do
        it "records at the `global events` level" do
          expect(snapshot_metric[:events][:queue_push_duration_in_millis].value).to be_kind_of(Integer)
        end

        it "records at the `pipeline` level" do
          expect(snapshot_metric[:pipelines][:main][:events][:queue_push_duration_in_millis].value).to be_kind_of(Integer)
        end

        it "records at the `plugin level" do
          expect(snapshot_metric[:pipelines][:main][:plugins][:inputs][myid][:events][:queue_push_duration_in_millis].value).to be_kind_of(Integer)
        end
      end
    end
  end

  context "WrappedSynchronousQueue" do
    let(:queue) { LogStash::WrappedSynchronousQueue.new(1024) }

    before do
      read_client.set_events_metric(metric.namespace([:stats, :events]))
      read_client.set_pipeline_metric(metric.namespace([:stats, :pipelines, :main, :events]))
    end

    include_examples "queue tests"
  end

  context "WrappedAckedQueue" do
    let(:path) { Stud::Temporary.directory }
    let(:queue) { LogStash::WrappedAckedQueue.new(path, 1024, 10, 1024, 1024, 1024, false, 4096) }

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
