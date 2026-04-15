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

describe "OpenTelemetry Metrics Export" do
  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
    @otel_collector = @fixture.get_service("otelcollector")
  end

  after(:all) do
    @fixture.teardown
  end

  after(:each) do
    @logstash.teardown
    @otel_collector.clear_metrics
  end

  let(:max_retry) { 60 }

  shared_examples "exports metrics to OTel Collector" do |protocol|
    it "exports Logstash metrics via #{protocol.upcase}" do
      # Configure Logstash with OTel settings
      endpoint = protocol == "grpc" ? @otel_collector.grpc_endpoint : @otel_collector.http_endpoint

      otel_settings = {
        "otel.metrics.enabled" => true,
        "otel.metrics.endpoint" => endpoint,
        "otel.metrics.protocol" => protocol,
        "otel.metrics.interval" => "5s",
        "otel.resource.attributes" => "environment=integration-test,test.protocol=#{protocol}"
      }

      # Merge OTel settings into Logstash config
      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")

      base_settings = YAML.load(File.read(settings_file)) || {}
      effective_settings = base_settings.merge(otel_settings)
      IO.write(settings_file, effective_settings.to_yaml)

      begin
        # Start Logstash with the pipeline config file
        @logstash.start_background(config_to_temp_file(@fixture.config))
        @logstash.wait_for_logstash

        # Wait for metrics to be received by collector
        expect(@otel_collector.wait_for_metrics(timeout: max_retry)).to be true

        # Read and verify metrics
        metrics = @otel_collector.read_metrics
        expect(metrics).not_to be_empty

        # Verify resource attributes
        resource_attrs = @otel_collector.get_resource_attributes(metrics)
        expect(resource_attrs["service.name"]).to eq("logstash")
        expect(resource_attrs["environment"]).to eq("integration-test")
        expect(resource_attrs["test.protocol"]).to eq(protocol)

        # Verify some expected metrics exist
        events_in = @otel_collector.find_metric(metrics, "logstash.events.in")
        expect(events_in).not_to be_nil, "Expected logstash.events.in metric to be present"

        events_out = @otel_collector.find_metric(metrics, "logstash.events.out")
        expect(events_out).not_to be_nil, "Expected logstash.events.out metric to be present"

        jvm_mem = @otel_collector.find_metric(metrics, "logstash.jvm.mem.heap_used_in_bytes")
        expect(jvm_mem).not_to be_nil, "Expected JVM memory metric to be present"

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
    it "sends metrics with authorization header" do
      otel_settings = {
        "otel.metrics.enabled" => true,
        "otel.metrics.endpoint" => @otel_collector.http_endpoint,
        "otel.metrics.protocol" => "http",
        "otel.metrics.interval" => "5s",
        "otel.metrics.authorization_header" => @otel_collector.auth_header
      }

      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")

      base_settings = YAML.load(File.read(settings_file)) || {}
      effective_settings = base_settings.merge(otel_settings)
      IO.write(settings_file, effective_settings.to_yaml)

      begin
        @logstash.start_background(config_to_temp_file(@fixture.config))
        @logstash.wait_for_logstash

        # Wait for metrics - if auth is working, collector will receive them
        expect(@otel_collector.wait_for_metrics(timeout: max_retry)).to be true

        metrics = @otel_collector.read_metrics
        expect(metrics).not_to be_empty

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
        "otel.metrics.endpoint" => @otel_collector.grpc_endpoint,
        "otel.metrics.protocol" => "grpc",
        "otel.metrics.interval" => "5s",
        "otel.service.name" => custom_service_name
      }

      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")

      base_settings = YAML.load(File.read(settings_file)) || {}
      effective_settings = base_settings.merge(otel_settings)
      IO.write(settings_file, effective_settings.to_yaml)

      begin
        @logstash.start_background(config_to_temp_file(@fixture.config))
        @logstash.wait_for_logstash

        expect(@otel_collector.wait_for_metrics(timeout: max_retry)).to be true

        metrics = @otel_collector.read_metrics
        resource_attrs = @otel_collector.get_resource_attributes(metrics)

        expect(resource_attrs["service.name"]).to eq(custom_service_name)

      ensure
        FileUtils.mv("#{settings_file}.original", settings_file) if File.exist?("#{settings_file}.original")
      end
    end

    it "uses OTEL_SERVICE_NAME environment variable" do
      custom_service_name = "env-var-logstash"

      otel_settings = {
        "otel.metrics.enabled" => true,
        "otel.metrics.endpoint" => @otel_collector.grpc_endpoint,
        "otel.metrics.protocol" => "grpc",
        "otel.metrics.interval" => "5s"
      }

      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")

      base_settings = YAML.load(File.read(settings_file)) || {}
      effective_settings = base_settings.merge(otel_settings)
      IO.write(settings_file, effective_settings.to_yaml)

      begin
        # Set OTEL_SERVICE_NAME env var before starting Logstash
        @logstash.env_variables = { "OTEL_SERVICE_NAME" => custom_service_name }
        @logstash.start_background(config_to_temp_file(@fixture.config))
        @logstash.wait_for_logstash

        expect(@otel_collector.wait_for_metrics(timeout: max_retry)).to be true

        metrics = @otel_collector.read_metrics
        resource_attrs = @otel_collector.get_resource_attributes(metrics)

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
        "otel.metrics.endpoint" => @otel_collector.grpc_endpoint,
        "otel.metrics.protocol" => "grpc",
        "otel.metrics.interval" => "5s"
      }

      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")

      base_settings = YAML.load(File.read(settings_file)) || {}
      effective_settings = base_settings.merge(otel_settings)
      IO.write(settings_file, effective_settings.to_yaml)

      begin
        @logstash.start_background(config_to_temp_file(@fixture.config))
        @logstash.wait_for_logstash

        # Wait a bit longer to ensure pipeline metrics are collected
        sleep 10

        expect(@otel_collector.wait_for_metrics(timeout: max_retry)).to be true

        metrics = @otel_collector.read_metrics

        # Check for pipeline-specific metrics
        pipeline_events_in = @otel_collector.find_metric(metrics, "logstash.pipeline.events.in")
        expect(pipeline_events_in).not_to be_nil, "Expected pipeline events.in metric"

        pipeline_events_out = @otel_collector.find_metric(metrics, "logstash.pipeline.events.out")
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
        "otel.metrics.endpoint" => @otel_collector.http_endpoint,
        "otel.metrics.protocol" => "http",
        "otel.metrics.interval" => "3s",
        "otel.metrics.authorization_header" => @otel_collector.auth_header,
        "otel.resource.attributes" => "deployment.environment=test,service.version=1.0.0",
        "otel.service.name" => "full-config-logstash"
      }

      settings_file = @logstash.application_settings_file
      FileUtils.cp(settings_file, "#{settings_file}.original")

      base_settings = YAML.load(File.read(settings_file)) || {}
      effective_settings = base_settings.merge(otel_settings)
      IO.write(settings_file, effective_settings.to_yaml)

      begin
        @logstash.start_background(config_to_temp_file(@fixture.config))
        @logstash.wait_for_logstash

        expect(@otel_collector.wait_for_metrics(timeout: max_retry)).to be true

        metrics = @otel_collector.read_metrics
        expect(metrics).not_to be_empty

        resource_attrs = @otel_collector.get_resource_attributes(metrics)

        # Verify all resource attributes
        expect(resource_attrs["service.name"]).to eq("full-config-logstash")
        expect(resource_attrs["deployment.environment"]).to eq("test")
        expect(resource_attrs["service.version"]).to eq("1.0.0")

        # Verify core metrics are present
        expect(@otel_collector.find_metric(metrics, "logstash.events.in")).not_to be_nil
        expect(@otel_collector.find_metric(metrics, "logstash.events.out")).not_to be_nil
        expect(@otel_collector.find_metric(metrics, "logstash.jvm.mem.heap_used_in_bytes")).not_to be_nil

      ensure
        FileUtils.mv("#{settings_file}.original", settings_file) if File.exist?("#{settings_file}.original")
      end
    end
  end
end
