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

describe LogStash::Instrument::PeriodicPoller::Otel do
  let(:collector) { LogStash::Instrument::Collector.new }
  let(:metric) { LogStash::Instrument::Metric.new(collector) }

  let(:pipeline_id) { :main }
  let(:pipeline) do
    double("pipeline",
      :collect_stats => nil,
      :collect_dlq_stats => nil
    )
  end

  let(:agent) do
    double("agent",
      :id => "test-node-id",
      :name => "test-node-name",
      :running_pipelines => { pipeline_id => pipeline },
      :running_user_defined_pipelines => { pipeline_id => pipeline },
      :capture_flow_metrics => nil
    )
  end

  let(:interval_time_value) { double("time_value", :to_seconds => 10, :to_millis => 10000) }

  let(:settings) do
    double("settings").tap do |s|
      allow(s).to receive(:get).with("otel.exporter.otlp.endpoint").and_return("http://localhost:4317")
      allow(s).to receive(:get).with("otel.metric.export.interval").and_return(interval_time_value)
      allow(s).to receive(:get).with("otel.exporter.otlp.protocol").and_return("grpc")
      allow(s).to receive(:get).with("otel.resource.attributes").and_return(nil)
      allow(s).to receive(:get).with("otel.exporter.otlp.headers").and_return(nil)
      allow(s).to receive(:get).with("otel.service.name").and_return(nil)
      allow(s).to receive(:get).with("otel.exporter.otlp.certificate").and_return(nil)
      allow(s).to receive(:get).with("otel.exporter.otlp.client.key").and_return(nil)
      allow(s).to receive(:get).with("otel.exporter.otlp.client.certificate").and_return(nil)
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
    java_import 'org.logstash.instrument.metrics.otel.OtelMetricsService'
    java_import 'org.logstash.instrument.metrics.otel.OtelMetricsConfig'
    allow(OtelMetricsService).to receive(:new).and_return(otel_service)
  end

  subject(:otel_poller) { described_class.new(metric, agent, settings) }

  describe "#initialize" do
    it "should initialize cleanly" do
      expect { otel_poller }.not_to raise_error
    end

    it "creates an OtelMetricsService with correct parameters" do
      expect(OtelMetricsService).to receive(:new).with(
        have_attributes(
          endpoint: "http://localhost:4317",
          node_id: "test-node-id",
          node_name: "test-node-name",
          interval_ms: 10000,
          protocol: "grpc",
          resource_attributes: nil,
          headers: nil,
          service_name: nil,
          certificate_path: nil,
          client_key_path: nil,
          client_certificate_path: nil
        )
      ).and_return(otel_service)

      otel_poller
    end

    context "with authorization header (ApiKey)" do
      let(:auth_password) { LogStash::Util::Password.new("Authorization=ApiKey my-secret-key") }
      let(:settings) do
        double("settings").tap do |s|
          allow(s).to receive(:get).with("otel.exporter.otlp.endpoint").and_return("https://apm.example.com")
          allow(s).to receive(:get).with("otel.metric.export.interval").and_return(interval_time_value)
          allow(s).to receive(:get).with("otel.exporter.otlp.protocol").and_return("http")
          allow(s).to receive(:get).with("otel.resource.attributes").and_return(nil)
          allow(s).to receive(:get).with("otel.exporter.otlp.headers").and_return(auth_password)
          allow(s).to receive(:get).with("otel.service.name").and_return(nil)
              allow(s).to receive(:get).with("otel.exporter.otlp.certificate").and_return(nil)
          allow(s).to receive(:get).with("otel.exporter.otlp.client.key").and_return(nil)
          allow(s).to receive(:get).with("otel.exporter.otlp.client.certificate").and_return(nil)
        end
      end

      it "extracts string value from Password and passes to OtelMetricsService" do
        expect(OtelMetricsService).to receive(:new).with(
          have_attributes(
            endpoint: "https://apm.example.com",
            headers: "Authorization=ApiKey my-secret-key"
          )
        ).and_return(otel_service)

        otel_poller
      end
    end

    context "with authorization header (Bearer token)" do
      let(:auth_password) { LogStash::Util::Password.new("Authorization=Bearer my-bearer-token") }
      let(:settings) do
        double("settings").tap do |s|
          allow(s).to receive(:get).with("otel.exporter.otlp.endpoint").and_return("https://apm.example.com")
          allow(s).to receive(:get).with("otel.metric.export.interval").and_return(interval_time_value)
          allow(s).to receive(:get).with("otel.exporter.otlp.protocol").and_return("http")
          allow(s).to receive(:get).with("otel.resource.attributes").and_return(nil)
          allow(s).to receive(:get).with("otel.exporter.otlp.headers").and_return(auth_password)
          allow(s).to receive(:get).with("otel.service.name").and_return(nil)
              allow(s).to receive(:get).with("otel.exporter.otlp.certificate").and_return(nil)
          allow(s).to receive(:get).with("otel.exporter.otlp.client.key").and_return(nil)
          allow(s).to receive(:get).with("otel.exporter.otlp.client.certificate").and_return(nil)
        end
      end

      it "extracts string value from Password and passes to OtelMetricsService" do
        expect(OtelMetricsService).to receive(:new).with(
          have_attributes(
            endpoint: "https://apm.example.com",
            headers: "Authorization=Bearer my-bearer-token"
          )
        ).and_return(otel_service)

        otel_poller
      end
    end

    context "with nil authorization header" do
      let(:settings) do
        double("settings").tap do |s|
          allow(s).to receive(:get).with("otel.exporter.otlp.endpoint").and_return("https://apm.example.com")
          allow(s).to receive(:get).with("otel.metric.export.interval").and_return(interval_time_value)
          allow(s).to receive(:get).with("otel.exporter.otlp.protocol").and_return("http")
          allow(s).to receive(:get).with("otel.resource.attributes").and_return(nil)
          allow(s).to receive(:get).with("otel.exporter.otlp.headers").and_return(nil)
          allow(s).to receive(:get).with("otel.service.name").and_return(nil)
              allow(s).to receive(:get).with("otel.exporter.otlp.certificate").and_return(nil)
          allow(s).to receive(:get).with("otel.exporter.otlp.client.key").and_return(nil)
          allow(s).to receive(:get).with("otel.exporter.otlp.client.certificate").and_return(nil)
        end
      end

      it "passes nil to OtelMetricsService when authorization header is not set" do
        expect(OtelMetricsService).to receive(:new).with(
          have_attributes(
            endpoint: "https://apm.example.com",
            headers: nil
          )
        ).and_return(otel_service)

        otel_poller
      end
    end

    context "with TLS certificate settings" do
      let(:settings) do
        double("settings").tap do |s|
          allow(s).to receive(:get).with("otel.exporter.otlp.endpoint").and_return("https://apm.example.com")
          allow(s).to receive(:get).with("otel.metric.export.interval").and_return(interval_time_value)
          allow(s).to receive(:get).with("otel.exporter.otlp.protocol").and_return("grpc")
          allow(s).to receive(:get).with("otel.resource.attributes").and_return(nil)
          allow(s).to receive(:get).with("otel.exporter.otlp.headers").and_return(nil)
          allow(s).to receive(:get).with("otel.service.name").and_return(nil)
              allow(s).to receive(:get).with("otel.exporter.otlp.certificate").and_return("/path/to/ca.pem")
          allow(s).to receive(:get).with("otel.exporter.otlp.client.key").and_return("/path/to/client.key")
          allow(s).to receive(:get).with("otel.exporter.otlp.client.certificate").and_return("/path/to/client.crt")
        end
      end

      it "passes certificate paths to OtelMetricsService" do
        expect(OtelMetricsService).to receive(:new).with(
          have_attributes(
            endpoint: "https://apm.example.com",
            certificate_path: "/path/to/ca.pem",
            client_key_path: "/path/to/client.key",
            client_certificate_path: "/path/to/client.crt"
          )
        ).and_return(otel_service)

        otel_poller
      end

      it "passes only trusted certificate path when client credentials are absent" do
        allow(settings).to receive(:get).with("otel.exporter.otlp.client.key").and_return(nil)
        allow(settings).to receive(:get).with("otel.exporter.otlp.client.certificate").and_return(nil)

        expect(OtelMetricsService).to receive(:new).with(
          have_attributes(
            certificate_path: "/path/to/ca.pem",
            client_key_path: nil,
            client_certificate_path: nil
          )
        ).and_return(otel_service)

        otel_poller
      end
    end

    context "with multiple pipelines" do
      let(:pipeline2_id) { :secondary }
      let(:pipeline2) do
        double("pipeline2",
          :collect_stats => nil,
          :collect_dlq_stats => nil
        )
      end

      let(:agent) do
        double("agent",
          :id => "test-node-id",
          :name => "test-node-name",
          :running_pipelines => { pipeline_id => pipeline, pipeline2_id => pipeline2 },
          :running_user_defined_pipelines => { pipeline_id => pipeline, pipeline2_id => pipeline2 },
          :capture_flow_metrics => nil
        )
      end

      it "registers a separate metric instrument per pipeline for the same metric name" do
        java_import 'io.opentelemetry.api.common.AttributeKey'
        pipeline_id_attr = AttributeKey.stringKey("pipeline.id")

        registered_pipeline_ids = []
        allow(otel_service).to receive(:registerObservableCounter) do |name, _desc, _unit, _supplier, attrs|
          registered_pipeline_ids << attrs.get(pipeline_id_attr) if name == "logstash.pipeline.events.in"
        end

        otel_poller.collect

        expect(registered_pipeline_ids).to contain_exactly("main", "secondary")
      end
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
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.queue.events", anything, anything, anything, anything
      )

      otel_poller
    end

    it "registers JVM metrics" do
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.mem.heap.used", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.mem.heap.committed", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.mem.heap.max", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.mem.heap.used_percent", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.mem.non_heap.used", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.mem.non_heap.committed", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerObservableCounter).with("logstash.jvm.gc.collection_count", anything, anything, anything, anything).twice
      expect(otel_service).to receive(:registerObservableCounter).with("logstash.jvm.gc.collection_time", anything, anything, anything, anything).twice
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.threads.count", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.threads.peak_count", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.process.open_file_descriptors", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.process.max_file_descriptors", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.process.cpu.percent", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerObservableCounter).with("logstash.jvm.process.cpu.total", anything, anything, anything, anything)
      expect(otel_service).to receive(:registerGauge).with("logstash.jvm.uptime", anything, anything, anything, anything)

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
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.os.cgroup.cpu.stat.elapsed_periods", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.os.cgroup.cpu.stat.nr_times_throttled", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.os.cgroup.cpu.stat.time_throttled", anything, anything, anything, anything
      )

      otel_poller
    end

    it "registers pipeline metrics for each running pipeline on first collect" do
      # Pipeline event counters
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.pipeline.events.in", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.pipeline.events.out", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerObservableCounter).with(
        "logstash.pipeline.events.filtered", anything, anything, anything, anything
      )

      # Pipeline queue gauges
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.pipeline.queue.events", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.pipeline.queue.capacity.page_capacity", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.pipeline.queue.capacity.max_size", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.pipeline.queue.capacity.max_unread_events", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.pipeline.queue.capacity.size", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.pipeline.queue.data.free_space", anything, anything, anything, anything
      )

      # Pipeline DLQ gauges
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.pipeline.dlq.queue_size", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.pipeline.dlq.max_queue_size", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.pipeline.dlq.dropped_events", anything, anything, anything, anything
      )
      expect(otel_service).to receive(:registerGauge).with(
        "logstash.pipeline.dlq.expired_events", anything, anything, anything, anything
      )

      otel_poller.collect
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

    context "with plugins" do
      let(:metric_store) do
        double("metric_store").tap do |store|
          allow(store).to receive(:get_shallow).and_return(nil)
          allow(store).to receive(:get_shallow)
            .with(:stats, :pipelines, :main, :plugins, :filters)
            .and_return({ :mutate_abc123 => {} })
          allow(store).to receive(:get_shallow)
            .with(:stats, :pipelines, :main, :plugins, :outputs)
            .and_return({ :elasticsearch_def456 => {} })
          allow(store).to receive(:get_shallow)
            .with(:stats, :pipelines, :main, :plugins, :inputs)
            .and_return({ :beats_ghi789 => {} })
        end
      end

      let(:snapshot) do
        double("snapshot", :metric_store => metric_store)
      end

      before do
        # First collect registers pipeline metrics
        otel_poller.collect
        # Stub snapshot and set it on the poller so plugin discovery works
        allow(collector).to receive(:snapshot_metric).and_return(snapshot)
        otel_poller.instance_variable_set(:@snapshot, snapshot)
      end

      it "registers plugin metrics for filters, outputs, and inputs" do
        # Expect 3 metrics per plugin (in, out, duration) x 3 plugins = 9 calls
        expect(otel_service).to receive(:registerObservableCounter).with(
          "logstash.plugin.events.in", anything, anything, anything, anything
        ).exactly(3).times
        expect(otel_service).to receive(:registerObservableCounter).with(
          "logstash.plugin.events.out", anything, anything, anything, anything
        ).exactly(3).times
        expect(otel_service).to receive(:registerObservableCounter).with(
          "logstash.plugin.events.duration", anything, anything, anything, anything
        ).exactly(3).times

        otel_poller.collect
      end

      it "only registers each plugin once across multiple collects" do
        # First collect in this test registers plugins
        otel_poller.collect

        # Second collect should not register the same plugins again
        expect(otel_service).not_to receive(:registerObservableCounter).with(
          "logstash.plugin.events.in", anything, anything, anything, anything
        )

        otel_poller.collect
      end
    end
  end

  describe "#stop" do
    before do
      otel_poller
    end

    it "flushes pending metrics before shutting down to avoid losing in-flight data" do
      expect(otel_service).to receive(:flush).ordered
      expect(otel_service).to receive(:shutdown).ordered
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

      it "returns nil for missing plugin metrics" do
        value = otel_poller.send(:get_plugin_metric_value, :main, :filters, :nonexistent_plugin, :events, :in)
        expect(value).to be_nil
      end
    end

    context "#get_total_queue_events" do
      let(:pipeline2) do
        double("pipeline2",
          :collect_stats => nil,
          :collect_dlq_stats => nil
        )
      end

      before do
        metric.gauge([:stats, :pipelines, :main, :queue], :events, 10)
        metric.gauge([:stats, :pipelines, :secondary, :queue], :events, 20)

        allow(agent).to receive(:running_user_defined_pipelines).and_return({
          :main => pipeline,
          :secondary => pipeline2
        })

        otel_poller.collect
      end

      it "sums queue events across all user pipelines" do
        total = otel_poller.send(:get_total_queue_events)
        expect(total).to eq(30)
      end
    end

    context "#get_plugin_metric_value" do
      before do
        metric.gauge([:stats, :pipelines, :main, :plugins, :filters, :mutate_abc, :events], :in, 500)
        metric.gauge([:stats, :pipelines, :main, :plugins, :filters, :mutate_abc, :events], :out, 450)
        otel_poller.collect
      end

      it "retrieves plugin metric values" do
        value = otel_poller.send(:get_plugin_metric_value, :main, :filters, :mutate_abc, :events, :in)
        expect(value).to eq(500)
      end

      it "retrieves different plugin metric paths" do
        value = otel_poller.send(:get_plugin_metric_value, :main, :filters, :mutate_abc, :events, :out)
        expect(value).to eq(450)
      end
    end
  end

  describe "#get_total_queue_events" do
    let(:pipeline2_id) { :secondary }
    let(:pipeline2) do
      double("pipeline2",
        :collect_stats => nil,
        :collect_dlq_stats => nil
      )
    end

    let(:agent) do
      double("agent",
        :id => "test-node-id",
        :name => "test-node-name",
        :running_pipelines => {
          pipeline_id => pipeline,
          pipeline2_id => pipeline2
        },
        :running_user_defined_pipelines => {
          pipeline_id => pipeline,
          pipeline2_id => pipeline2
        },
        :capture_flow_metrics => nil
      )
    end

    before do
      otel_poller
      metric.gauge([:stats, :pipelines, pipeline_id, :queue], :events, 10)
      metric.gauge([:stats, :pipelines, pipeline2_id, :queue], :events, 20)
      otel_poller.collect
    end

    it "sums queue events from user-defined pipelines" do
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
      # Reset cached cgroup resolution state so mocks take effect regardless of test order
      LogStash::Instrument::PeriodicPoller::Cgroup.instance_variable_set(:@resolved, false)
      LogStash::Instrument::PeriodicPoller::Cgroup.instance_variable_set(:@active_resources, nil)
      LogStash::Instrument::PeriodicPoller::Cgroup.instance_variable_set(:@active_label, nil)
      LogStash::Instrument::PeriodicPoller::Cgroup.instance_variable_set(:@logged_empty, false)
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

  describe "attribute creation" do
    before do
      otel_poller
    end

    describe "#create_pipeline_attributes" do

      before do
        java_import 'io.opentelemetry.api.common.AttributeKey'
      end

      it "creates Attributes with pipeline.id" do
        attrs = otel_poller.send(:create_pipeline_attributes, :main)
        expect(attrs.get(AttributeKey.stringKey("pipeline.id"))).to eq("main")
      end

      it "converts symbol pipeline_id to string" do
        attrs = otel_poller.send(:create_pipeline_attributes, :my_pipeline)
        expect(attrs.get(AttributeKey.stringKey("pipeline.id"))).to eq("my_pipeline")
      end
    end

    describe "#create_plugin_attributes" do

      before do
        java_import 'io.opentelemetry.api.common.AttributeKey'
      end

      it "creates Attributes with pipeline.id, plugin.type, and plugin.id" do
        attrs = otel_poller.send(:create_plugin_attributes, :main, :filters, :mutate_abc123)

        expect(attrs.get(AttributeKey.stringKey("pipeline.id"))).to eq("main")
        expect(attrs.get(AttributeKey.stringKey("plugin.type"))).to eq("filters")
        expect(attrs.get(AttributeKey.stringKey("plugin.id"))).to eq("mutate_abc123")
      end

      it "converts all symbol arguments to strings" do
        attrs = otel_poller.send(:create_plugin_attributes, :secondary, :outputs, :elasticsearch_xyz)

        expect(attrs.get(AttributeKey.stringKey("pipeline.id"))).to eq("secondary")
        expect(attrs.get(AttributeKey.stringKey("plugin.type"))).to eq("outputs")
        expect(attrs.get(AttributeKey.stringKey("plugin.id"))).to eq("elasticsearch_xyz")
      end
    end
  end
end
