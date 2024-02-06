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

require "spec_helper"

describe LogStash::Api::Commands::Stats do
  # enable PQ to ensure PQ-related metrics are present
  include_context "api setup", {"queue.type" => "persisted"}

  let(:report_method) { :run }
  let(:extended_pipeline) { nil }
  let(:opts) { {} }
  subject(:report) do
    factory = ::LogStash::Api::CommandFactory.new(LogStash::Api::Service.new(@agent))
    if extended_pipeline
      factory.build(:stats).send(report_method, "main", extended_pipeline, opts)
    else
      factory.build(:stats).send(report_method)
    end
  end

  let(:report_class) { described_class }

  describe "#plugins_stats_report" do
    let(:report_method) { :plugins_stats_report }
    # Enforce just the structure
    let(:extended_pipeline) {
      {
      :queue => "fake_queue",
      :hash => "fake_hash",
      :ephemeral_id => "fake_epehemeral_id",
      :vertices => "fake_vertices"
      }
    }
    # TODO pass in a real sample vertex
#    let(:opts) {
#      {
#        :vertices => "fake vertices"
#      }
#    }
    it "check keys" do
      expect(report.keys).to include(
        :queue,
        :hash,
        :ephemeral_id,
        # TODO re-add vertices -- see above
#        :vertices
      )
    end
  end

  describe "#events" do
    let(:report_method) { :events }

    it "return events information" do
      expect(report.keys).to include(
        :in,
        :filtered,
        :out,
        :duration_in_millis,
        :queue_push_duration_in_millis)
    end
  end

  describe "#metric flows" do
    let(:report_method) { :flow }

    it "should validate flow metric keys are exist" do
      expect(report.keys).to include(
                               :input_throughput,
                               :output_throughput,
                               :filter_throughput,
                               :queue_backpressure,
                               :worker_concurrency)
    end
  end

  describe "#hot_threads" do
    let(:report_method) { :hot_threads }

    it "should return hot threads information as a string" do
      expect(report.to_s).to be_a(String)
    end

    it "should return hot threads info as a hash" do
      expect(report.to_hash).to be_a(Hash)
    end
  end

  describe "memory stats" do
    let(:report_method) { :memory }

    it "return hot threads information" do
      expect(report).not_to be_empty
    end

    it "return memory information" do
      expect(report.keys).to include(
        :heap_used_percent,
        :heap_committed_in_bytes,
        :heap_max_in_bytes,
        :heap_used_in_bytes,
        :non_heap_used_in_bytes,
        :non_heap_committed_in_bytes,
        :pools
      )
    end
  end

  describe "jvm stats" do
    let(:report_method) { :jvm }

    it "return jvm information" do
      expect(report.keys).to include(
        :threads,
        :mem,
        :gc,
        :uptime_in_millis
      )
      expect(report[:threads].keys).to include(
        :count,
        :peak_count
      )
    end
  end

  describe "reloads stats" do
    let(:report_method) { :reloads }

    it "return reloads information" do
      expect(report.keys).to include(
      :successes,
      :failures,
      )
    end
  end

  describe "pipeline stats" do
    let(:report_method) { :pipeline }
    it "returns information on existing pipeline" do
      expect(report.keys).to include(:main)
    end
    context "for each pipeline" do
      it "returns information on pipeline" do
        expect(report[:main].keys).to include(
          :events,
          :flow,
          :plugins,
          :reloads,
          :queue,
        )
      end
      it "returns event information" do
        expect(report[:main][:events].keys).to include(
          :in,
          :filtered,
          :duration_in_millis,
          :out,
          :queue_push_duration_in_millis
        )
      end
      it "returns flow metric information" do
        expect(report[:main][:flow].keys).to include(
                                                 :output_throughput,
                                                 :filter_throughput,
                                                 :queue_backpressure,
                                                 :worker_concurrency,
                                                 :worker_utilization,
                                                 :input_throughput,
                                                 :queue_persisted_growth_bytes,
                                                 :queue_persisted_growth_events
                                               )
      end
      it "returns queue metric information" do
        expect(report[:main][:queue].keys).to include(
                                               :capacity,
                                               :events,
                                               :type,
                                               :data)
        expect(report[:main][:queue][:capacity].keys).to include(
                                                           :page_capacity_in_bytes,
                                                           :max_queue_size_in_bytes,
                                                           :queue_size_in_bytes,
                                                           :max_unread_events)
        expect(report[:main][:queue][:data].keys).to include(
                                                           :storage_type,
                                                           :path,
                                                           :free_space_in_bytes)
      end
    end
    context "when using multiple pipelines" do
      before(:each) do
        expect(LogStash::Config::PipelinesInfo).to receive(:format_pipelines_info).and_return([
          {"id" => :main},
          {"id" => :secondary},
        ])
      end
      it "contains metrics for all pipelines" do
        expect(report.keys).to include(:main, :secondary)
      end
    end
  end
end
