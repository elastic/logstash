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

require 'json'
require 'fileutils'

class OtelcollectorService < Service
  OTEL_DATA_DIR = "/tmp/ls_integration/otel"
  OTEL_METRICS_FILE = "#{OTEL_DATA_DIR}/metrics.json"
  OTEL_CONFIG_FILE = "#{OTEL_DATA_DIR}/otel-config.yaml"
  OTEL_PID_FILE = "#{OTEL_DATA_DIR}/otel.pid"

  # HTTP receiver port (for Logstash to send metrics)
  HTTP_PORT = 4318
  # gRPC receiver port
  GRPC_PORT = 4317

  # Authorization header expected by the collector
  AUTH_HEADER = "ApiKey test-integration-key"

  def initialize(settings)
    super("otelcollector", settings)
  end

  def http_endpoint
    "http://localhost:#{HTTP_PORT}"
  end

  def grpc_endpoint
    "http://localhost:#{GRPC_PORT}"
  end

  def auth_header
    AUTH_HEADER
  end

  def metrics_file
    OTEL_METRICS_FILE
  end

  def data_dir
    OTEL_DATA_DIR
  end

  def wait_for_metric(name, timeout: 60)
    start_time = Time.now
    puts "Waiting for metric '#{name}' in #{OTEL_METRICS_FILE}"
    while Time.now - start_time < timeout
      if File.exist?(OTEL_METRICS_FILE) && File.size(OTEL_METRICS_FILE) > 0
        metric = find_metric(read_metrics, name)
        return metric if metric
      end
      sleep 1
    end
    puts "Timed out waiting for metric '#{name}'"
    nil
  end

  def read_metrics
    return [] unless File.exist?(OTEL_METRICS_FILE)

    metrics = []
    File.readlines(OTEL_METRICS_FILE).each do |line|
      next if line.strip.empty?
      begin
        metrics << JSON.parse(line)
      rescue JSON::ParserError => e
        puts "Warning: Could not parse metrics line: #{e.message}"
      end
    end
    metrics
  end

  def find_metric(metrics, name)
    metrics.each do |batch|
      resource_metrics = batch.dig("resourceMetrics") || []
      resource_metrics.each do |rm|
        scope_metrics = rm.dig("scopeMetrics") || []
        scope_metrics.each do |sm|
          (sm["metrics"] || []).each do |m|
            return m if m["name"] == name
          end
        end
      end
    end
    nil
  end

  def get_resource_attributes(metrics)
    return {} if metrics.empty?
    attrs = {}
    # Use the last batch to get the most recent resource attributes
    resource = metrics.last.dig("resourceMetrics", 0, "resource", "attributes") || []
    resource.each do |attr|
      key = attr["key"]
      value = attr.dig("value", "stringValue") || attr.dig("value", "intValue")
      attrs[key] = value
    end
    attrs
  end

  def clear_metrics
    if File.exist?(OTEL_METRICS_FILE)
      File.open(OTEL_METRICS_FILE, 'w') {}
    end
  end
end
