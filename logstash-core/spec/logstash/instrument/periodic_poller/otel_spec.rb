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
require "logstash/instrument/periodic_poller/otel"
require "logstash/instrument/collector"

describe LogStash::Instrument::PeriodicPoller::OTel do
  let(:collector) { LogStash::Instrument::Collector.new }
  let(:metric) { LogStash::Instrument::Metric.new(collector) }
  let(:agent_metric) { double("agent_metric", :collector => collector) }

  let(:pipeline_id) { :main }
  let(:pipeline) do
    double("pipeline",
      :system? => false,
      :collect_stats => nil,
      :collect_dlq_stats => nil
    )
  end
  let(:pipelines_registry) do
    double("pipelines_registry",
      :running_pipelines => { pipeline_id => pipeline }
    )
  end

  let(:agent) do
    double("agent",
      :id => "test-node-id",
      :name => "test-node-name",
      :metric => agent_metric,
      :pipelines_registry => pipelines_registry,
      :running_user_defined_pipelines => { pipeline_id => pipeline },
      :capture_flow_metrics => nil
    )
  end

  let(:settings) do
    double("settings").tap do |s|
      allow(s).to receive(:get).with("otel.metrics.endpoint").and_return("http://localhost:4317")
      allow(s).to receive(:get).with("otel.metrics.interval").and_return(10)
      allow(s).to receive(:get).with("otel.metrics.protocol").and_return("grpc")
      allow(s).to receive(:get).with("otel.resource.attributes").and_return(nil)
    end
  end

  let(:otel_service) do
    double("otel_service",
      :registerGauge => nil,
      :registerObservableCounter => nil,
      :flush => nil,
      :shutdown => nil
    )
  end

  before do
    allow(OTelMetricsService).to receive(:new).and_return(otel_service)
  end

  subject(:otel_poller) { described_class.new(metric, agent, settings) }

  describe "#initialize" do
    it "should initialize cleanly" do
      expect { otel_poller }.not_to raise_error
    end

    it "creates an OTelMetricsService with correct parameters" do
      expect(OTelMetricsService).to receive(:new).with(
        "http://localhost:4317",
        "test-node-id",
        "test-node-name",
        10,
        "grpc",
        nil
      ).and_return(otel_service)

      otel_poller
    end

    it "registers global metrics" do
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.events.in", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.events.out", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.events.filtered", anything, anything, anything, anything
      )

      otel_poller
    end

    it "registers cgroup metrics" do
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.os.cgroup.cpuacct.usage", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.os.cgroup.cpu.cfs_period", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.os.cgroup.cpu.cfs_quota", anything, anything, anything, anything
      )

      otel_poller
    end

    it "registers pipeline metrics for each running pipeline" do
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.pipeline.events.in", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.pipeline.events.out", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.pipeline.events.filtered", anything, anything, anything, anything
      )

      otel_poller
    end
  end

  describe "#collect" do
    before do
      otel_poller
    end

    it "collects pipeline stats from each running pipeline" do
      expect(pipeline).to receive(:collect_stats)
      otel_poller.collect
    end

    it "collects DLQ stats from each running pipeline" do
      expect(pipeline).to receive(:collect_dlq_stats)
      otel_poller.collect
    end

    it "captures flow metrics from the agent" do
      expect(agent).to receive(:capture_flow_metrics)
      otel_poller.collect
    end

    it "collects cgroup metrics via Os.collect_cgroup" do
      expect(LogStash::Instrument::PeriodicPoller::Os).to receive(:collect_cgroup).with(metric)
      otel_poller.collect
    end

    it "refreshes the metric store snapshot" do
      initial_snapshot = otel_poller.instance_variable_get(:@snapshot)
      otel_poller.collect
      new_snapshot = otel_poller.instance_variable_get(:@snapshot)
      expect(new_snapshot).not_to be(initial_snapshot)
    end
  end

  describe "#stop" do
    before do
      otel_poller
    end

    it "flushes and shuts down the OTel service" do
      expect(otel_service).to receive(:flush)
      expect(otel_service).to receive(:shutdown)
      otel_poller.stop
    end
  end

  describe "metric value retrieval" do
    before do
      otel_poller
    end

    context "when metrics exist in the store" do
      before do
        metric.gauge([:stats, :events], :in, 100)
        metric.gauge([:stats, :events], :out, 50)
        metric.gauge([:stats, :pipelines, pipeline_id, :queue], :events, 25)
        otel_poller.collect
      end

      it "retrieves global metric values" do
        value = otel_poller.send(:get_metric_value, :stats, :events, :in)
        expect(value).to eq(100)
      end

      it "retrieves pipeline metric values" do
        value = otel_poller.send(:get_pipeline_metric_value, pipeline_id, :queue, :events)
        expect(value).to eq(25)
      end
    end

    context "when metrics do not exist" do
      it "returns nil for missing metrics" do
        value = otel_poller.send(:get_metric_value, :nonexistent, :path)
        expect(value).to be_nil
      end

      it "returns nil for missing pipeline metrics" do
        value = otel_poller.send(:get_pipeline_metric_value, :nonexistent_pipeline, :events, :in)
        expect(value).to be_nil
      end
    end
  end

  describe "#get_total_queue_events" do
    let(:pipeline2_id) { :secondary }
    let(:pipeline2) { double("pipeline2", :system? => false) }
    let(:system_pipeline) { double("system_pipeline", :system? => true) }

    let(:pipelines_registry) do
      double("pipelines_registry",
        :running_pipelines => {
          pipeline_id => pipeline,
          pipeline2_id => pipeline2,
          :monitoring => system_pipeline
        }
      )
    end

    before do
      otel_poller
      metric.gauge([:stats, :pipelines, pipeline_id, :queue], :events, 10)
      metric.gauge([:stats, :pipelines, pipeline2_id, :queue], :events, 20)
      metric.gauge([:stats, :pipelines, :monitoring, :queue], :events, 5)
      otel_poller.collect
    end

    it "sums queue events from non-system pipelines only" do
      total = otel_poller.send(:get_total_queue_events)
      expect(total).to eq(30)
    end
  end

  context "with mocked cgroup environment" do
    let(:relative_path) { "/docker/abc123" }
    let(:proc_self_cgroup_content) do
      %W(4:cpuacct:#{relative_path}
         3:cpu:#{relative_path})
    end

    let(:cpuacct_usage) { 1982 }
    let(:cpu_period_micros) { 100000 }
    let(:cpu_quota_micros) { 50000 }
    let(:cpu_stat_file_content) do
      ["nr_periods 10", "nr_throttled 2", "throttled_time 1000000"]
    end

    before do
      allow(::File).to receive(:exist?).and_return(true)
      allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpuacct#{relative_path}/cpuacct.usage").and_return([cpuacct_usage])
      allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.cfs_period_us").and_return([cpu_period_micros])
      allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.cfs_quota_us").and_return([cpu_quota_micros])
      allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.stat").and_return(cpu_stat_file_content)
      allow(IO).to receive(:readlines).with("/proc/self/cgroup").and_return(proc_self_cgroup_content)
    end

    describe "cgroup metrics collection" do
      let(:snapshot_store) { metric.collector.snapshot_metric.metric_store }

      before do
        otel_poller.collect
      end

      def mval(*metric_path)
        metric_path.reduce(snapshot_store.get_shallow(:os)) { |acc, k| acc[k] }.value
      end

      it "collects cpuacct usage" do
        expect(mval(:cgroup, :cpuacct, :usage_nanos)).to eq(cpuacct_usage)
      end

      it "collects cpu cfs_period" do
        expect(mval(:cgroup, :cpu, :cfs_period_micros)).to eq(cpu_period_micros)
      end

      it "collects cpu cfs_quota" do
        expect(mval(:cgroup, :cpu, :cfs_quota_micros)).to eq(cpu_quota_micros)
      end

      it "collects cpu stat metrics" do
        expect(mval(:cgroup, :cpu, :stat, :number_of_elapsed_periods)).to eq(10)
        expect(mval(:cgroup, :cpu, :stat, :number_of_times_throttled)).to eq(2)
        expect(mval(:cgroup, :cpu, :stat, :time_throttled_nanos)).to eq(1000000)
      end
    end
  end

  describe "create_pipeline_attributes" do
    before do
      otel_poller
    end

    it "creates Attributes with pipeline.id" do
      attrs = otel_poller.send(:create_pipeline_attributes, :main)
      expect(attrs.get(AttributeKey.stringKey("pipeline.id"))).to eq("main")
    end
  end
end
