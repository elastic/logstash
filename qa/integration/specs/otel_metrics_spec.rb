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

require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../framework/helpers'
require_relative '../services/logstash_service'
require_relative '../services/otelcollector_service'
require "logstash/devutils/rspec/spec_helper"
require "stud/try"
require "json"
require "yaml"

describe "OpenTelemetry Metrics Export" do
  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
    @otel_collector = @fixture.get_service("otelcollector")
  end

  after(:all) do
    @fixture.teardown
  end

  before(:each) do
    # Clear metrics twice with a delay to ensure any buffered data from previous tests
    # is flushed by the OTel Collector's batch processor (1s timeout) and then removed
    @otel_collector.clear_metrics
    sleep 2
    @otel_collector.clear_metrics
  end

  after(:each) do
    @logstash.teardown
  end

  let(:max_retry) { 60 }

  shared_examples "exports metrics to OTel Collector" do |protocol|
    it "exports Logstash metrics via #{protocol.upcase}" do
      # Configure Logstash with OTel settings
      endpoint = protocol == "grpc" ? @otel_collector.grpc_endpoint : @otel_collector.http_endpoint

      otel_settings = {
        "otel.metrics.enabled" => true,
        "otel.exporter.otlp.endpoint" => endpoint,
        "otel.exporter.otlp.protocol" => protocol,
        "otel.metric.export.interval" => "5s",
        "otel.resource.attributes" => "environment=integration-test,test.protocol=#{protocol}"
      }

      # Write OTel settings to Logstash config (fresh file, no merging)
      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")

      # Write settings fresh to avoid any data accumulation from previous tests
      IO.write(settings_file, otel_settings.to_yaml)

      # Debug: print settings file content
      puts "Settings file (#{settings_file}):"
      puts File.read(settings_file)

      begin
        # Start Logstash with the pipeline config file
        @logstash.start_background(@fixture.config)
        @logstash.wait_for_logstash

        # Wait until the specific metrics appear in the collector output
        events_in = @otel_collector.wait_for_metric("logstash.events.in", timeout: max_retry)
        expect(events_in).not_to be_nil, "Expected logstash.events.in metric to be present"

        events_out = @otel_collector.wait_for_metric("logstash.events.out", timeout: max_retry)
        expect(events_out).not_to be_nil, "Expected logstash.events.out metric to be present"

        # Read all metrics to verify resource attributes
        metrics = @otel_collector.read_metrics
        resource_attrs = @otel_collector.get_resource_attributes(metrics)
        puts "Resource attributes: #{resource_attrs.inspect}"

        # Verify resource attributes
        expect(resource_attrs["service.name"]).to eq("logstash")
        expect(resource_attrs["environment"]).to eq("integration-test")
        expect(resource_attrs["test.protocol"]).to eq(protocol)

      ensure
        FileUtils.mv("#{settings_file}.original", settings_file) if File.exist?("#{settings_file}.original")
      end
    end
  end

  context "with gRPC protocol" do
    include_examples "exports metrics to OTel Collector", "grpc"
  end

  context "with HTTP protocol" do
    include_examples "exports metrics to OTel Collector", "http"
  end

  context "with authorization header" do
    it "sends metrics to authenticated endpoint with valid Bearer token" do
      otel_settings = {
        "otel.metrics.enabled" => true,
        "otel.exporter.otlp.endpoint" => @otel_collector.auth_http_endpoint,
        "otel.exporter.otlp.protocol" => "http",
        "otel.metric.export.interval" => "5s",
        "otel.exporter.otlp.headers" => @otel_collector.auth_header
      }

      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")
      IO.write(settings_file, otel_settings.to_yaml)

      begin
        @logstash.start_background(@fixture.config)
        @logstash.wait_for_logstash

        # The authenticated endpoint requires a valid Bearer token — verify metrics arrive
        events_in = @otel_collector.wait_for_metric("logstash.events.in", timeout: max_retry)
        expect(events_in).not_to be_nil, "Expected logstash.events.in metric to be present on authenticated endpoint"

      ensure
        FileUtils.mv("#{settings_file}.original", settings_file) if File.exist?("#{settings_file}.original")
      end
    end

    it "does not deliver metrics to authenticated endpoint without a Bearer token" do
      otel_settings = {
        "otel.metrics.enabled" => true,
        "otel.exporter.otlp.endpoint" => @otel_collector.auth_http_endpoint,
        "otel.exporter.otlp.protocol" => "http",
        "otel.metric.export.interval" => "5s"
        # No headers — request will be rejected by the collector's bearertokenauth extension
      }

      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")
      IO.write(settings_file, otel_settings.to_yaml)

      begin
        @logstash.start_background(@fixture.config)
        @logstash.wait_for_logstash

        # Give Logstash enough time to attempt metric export; requests should be rejected
        events_in = @otel_collector.wait_for_metric("logstash.events.in", timeout: 20)
        expect(events_in).to be_nil, "Expected no metrics to arrive when auth header is missing"

      ensure
        FileUtils.mv("#{settings_file}.original", settings_file) if File.exist?("#{settings_file}.original")
      end
    end
  end

  context "with custom service name" do
    it "uses custom service name from settings" do
      custom_service_name = "my-custom-logstash"

      otel_settings = {
        "otel.metrics.enabled" => true,
        "otel.exporter.otlp.endpoint" => @otel_collector.grpc_endpoint,
        "otel.exporter.otlp.protocol" => "grpc",
        "otel.metric.export.interval" => "5s",
        "otel.service.name" => custom_service_name
      }

      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")
      IO.write(settings_file, otel_settings.to_yaml)

      puts "Settings file (#{settings_file}):"
      puts File.read(settings_file)

      begin
        @logstash.start_background(@fixture.config)
        @logstash.wait_for_logstash

        events_in = @otel_collector.wait_for_metric("logstash.events.in", timeout: max_retry)
        expect(events_in).not_to be_nil, "Expected logstash.events.in metric to be present"

        metrics = @otel_collector.read_metrics
        resource_attrs = @otel_collector.get_resource_attributes(metrics)
        puts "Resource attributes: #{resource_attrs.inspect}"

        expect(resource_attrs["service.name"]).to eq(custom_service_name)

      ensure
        FileUtils.mv("#{settings_file}.original", settings_file) if File.exist?("#{settings_file}.original")
      end
    end

    it "uses otel.service.name system property" do
      custom_service_name = "sysprop-logstash"

      otel_settings = {
        "otel.metrics.enabled" => true,
        "otel.exporter.otlp.endpoint" => @otel_collector.grpc_endpoint,
        "otel.exporter.otlp.protocol" => "grpc",
        "otel.metric.export.interval" => "5s"
      }

      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")
      IO.write(settings_file, otel_settings.to_yaml)

      puts "Settings file (#{settings_file}):"
      puts File.read(settings_file)

      begin
        # Set otel.service.name system property via LS_JAVA_OPTS before starting Logstash
        @logstash.env_variables = { "LS_JAVA_OPTS" => "-Dotel.service.name=#{custom_service_name}" }
        puts "LS_JAVA_OPTS: -Dotel.service.name=#{custom_service_name}"
        @logstash.start_background(@fixture.config)
        @logstash.wait_for_logstash

        events_in = @otel_collector.wait_for_metric("logstash.events.in", timeout: max_retry)
        expect(events_in).not_to be_nil, "Expected logstash.events.in metric to be present"

        metrics = @otel_collector.read_metrics
        resource_attrs = @otel_collector.get_resource_attributes(metrics)
        puts "Resource attributes: #{resource_attrs.inspect}"

        expect(resource_attrs["service.name"]).to eq(custom_service_name)

      ensure
        @logstash.env_variables = nil
        FileUtils.mv("#{settings_file}.original", settings_file) if File.exist?("#{settings_file}.original")
      end
    end
  end

  context "with pipeline metrics" do
    it "exports pipeline-specific metrics" do
      otel_settings = {
        "otel.metrics.enabled" => true,
        "otel.exporter.otlp.endpoint" => @otel_collector.grpc_endpoint,
        "otel.exporter.otlp.protocol" => "grpc",
        "otel.metric.export.interval" => "5s"
      }

      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")
      IO.write(settings_file, otel_settings.to_yaml)

      begin
        @logstash.start_background(@fixture.config)
        @logstash.wait_for_logstash

        # Pipeline metrics are registered dynamically when pipelines start;
        # poll until they appear rather than sleeping a fixed duration.
        pipeline_events_in = @otel_collector.wait_for_metric("logstash.pipeline.events.in", timeout: max_retry)
        expect(pipeline_events_in).not_to be_nil, "Expected pipeline events.in metric"

        pipeline_events_out = @otel_collector.wait_for_metric("logstash.pipeline.events.out", timeout: max_retry)
        expect(pipeline_events_out).not_to be_nil, "Expected pipeline events.out metric"

      ensure
        FileUtils.mv("#{settings_file}.original", settings_file) if File.exist?("#{settings_file}.original")
      end
    end
  end

  context "all OTel settings" do
    it "uses all configuration options together" do
      otel_settings = {
        "otel.metrics.enabled" => true,
        "otel.exporter.otlp.endpoint" => @otel_collector.http_endpoint,
        "otel.exporter.otlp.protocol" => "http",
        "otel.metric.export.interval" => "3s",
        "otel.exporter.otlp.headers" => @otel_collector.auth_header,
        "otel.resource.attributes" => "deployment.environment=test,service.version=1.0.0",
        "otel.service.name" => "full-config-logstash"
      }

      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")
      IO.write(settings_file, otel_settings.to_yaml)

      puts "Settings file (#{settings_file}):"
      puts File.read(settings_file)

      begin
        @logstash.start_background(@fixture.config)
        @logstash.wait_for_logstash

        events_in = @otel_collector.wait_for_metric("logstash.events.in", timeout: max_retry)
        expect(events_in).not_to be_nil, "Expected logstash.events.in metric to be present"

        events_out = @otel_collector.wait_for_metric("logstash.events.out", timeout: max_retry)
        expect(events_out).not_to be_nil, "Expected logstash.events.out metric to be present"

        metrics = @otel_collector.read_metrics
        resource_attrs = @otel_collector.get_resource_attributes(metrics)
        puts "Resource attributes: #{resource_attrs.inspect}"

        # Verify all resource attributes
        expect(resource_attrs["service.name"]).to eq("full-config-logstash")
        expect(resource_attrs["deployment.environment"]).to eq("test")
        expect(resource_attrs["service.version"]).to eq("1.0.0")

      ensure
        FileUtils.mv("#{settings_file}.original", settings_file) if File.exist?("#{settings_file}.original")
      end
    end
  end
end
