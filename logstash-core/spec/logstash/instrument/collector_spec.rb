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

require "logstash/instrument/collector"
require "spec_helper"

describe LogStash::Instrument::Collector do
  subject(:metrics_collector) { LogStash::Instrument::Collector.new }
  describe "#push" do
    let(:namespaces_path) { [:root, :pipelines, :pipelines01] }
    let(:key) { :my_key }

    context "when the `MetricType` exist" do
      it "store the metric of type `counter`" do
        subject.push(namespaces_path, key, :counter, :increment)
      end
    end

    context "when the `MetricType` doesn't exist" do
      let(:wrong_type) { :donotexist }

      it "logs an error but dont crash" do
        expect(subject.logger).to receive(:error)
          .with("Collector: Cannot create concrete class for this metric type",
        hash_including({ :type => wrong_type, :namespaces_path => namespaces_path }))

          subject.push(namespaces_path, key, wrong_type, :increment)
      end
    end

    context "when there is a conflict with the metric key" do
      let(:conflicting_namespaces) { [namespaces_path, key].flatten }

      it "logs an error but dont crash" do
        subject.push(namespaces_path, key, :counter, :increment)

        expect(subject.logger).to receive(:error)
          .with("Collector: Cannot record metric",
          hash_including({ :exception => instance_of(LogStash::Instrument::MetricStore::NamespacesExpectedError) }))

          subject.push(conflicting_namespaces, :random_key, :counter, :increment)
      end
    end
  end

  describe '#get' do
    let(:namespaces_path) { [:root, :pipelines, :pipelines01] }
    let(:key) { :my_key }

    {
      counter: LogStash::Instrument::MetricType::Counter,
      gauge:   LogStash::Instrument::MetricType::Gauge,
      uptime:  org.logstash.instrument.metrics.UptimeMetric,
      timer:   org.logstash.instrument.metrics.timer.TimerMetric,
    }.each do |type, type_specific_implementation|
      context "with (type: `#{type}`)" do
        it "gets an instance of #{type_specific_implementation}" do
          expect(metrics_collector.get(namespaces_path, key, type)).to be_a_kind_of(type_specific_implementation)
        end

        it 'gets a singleton instance from multiple consecutive calls' do
          first = metrics_collector.get(namespaces_path, key, type)
          second = metrics_collector.get(namespaces_path, key, type)
          expect(second).to equal(first)
        end
      end
    end
  end

  describe "#snapshot_metric" do
    it "return a `LogStash::Instrument::MetricStore`" do
      expect(subject.snapshot_metric).to be_kind_of(LogStash::Instrument::Snapshot)
    end

    it "returns a clone of the metric store" do
      expect(subject.snapshot_metric).not_to eq(subject.snapshot_metric)
    end
  end
end
