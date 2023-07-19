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
require 'logstash/instrument/collector'
require "logstash/filter_delegator"
require "support/shared_contexts"

describe LogStash::FilterDelegator do
  include_context "execution_context"

  let(:filter_id) { "my-filter" }
  let(:config) do
    { "host" => "127.0.0.1", "id" => filter_id }
  end
  let(:collector) {LogStash::Instrument::Collector.new}
  let(:metric) { LogStash::Instrument::Metric.new(collector).namespace(:null) }
  let(:events) { [LogStash::Event.new, LogStash::Event.new] }

  before :each do
    allow(pipeline).to receive(:id).and_return(pipeline_id)
  end

  let(:plugin_klass) do
    Class.new(LogStash::Filters::Base) do
      config_name "super_plugin"
      config :host, :validate => :string
      def register; end
    end
  end

  subject {
    LogStash::Plugins::PluginFactory.filter_delegator(
        described_class, plugin_klass, config, metric, execution_context
    )
  }

  context "when the plugin support flush" do
    let(:plugin_klass) do
      Class.new(LogStash::Filters::Base) do
        config_name "super_plugin"
        config :host, :validate => :string
        def register; end
        def flush(options = {}); @events; end

        def filter(event)
          @events ||= []
          @events << event
          event.cancel
        end
      end
    end

    it "defines a flush method" do
      expect(subject.has_flush).to be_truthy
    end

    context "when the flush return events" do
      it "increments the out" do
        subject.multi_filter([LogStash::Event.new])
        subject.flush({})
        expect(collector.snapshot_metric.metric_store.get_with_path("/null")[:null]["my-filter".to_sym][:events][:out].value).to eq(1)
      end
    end

    context "when the flush doesn't return anything" do
      it "doesnt increment the out" do
        expect(metric).not_to receive(:increment)
        subject.flush({})
      end
    end

    context "when the filter buffer events" do
      it "has incremented :in" do
        subject.multi_filter(events)
        expect(collector.snapshot_metric.metric_store.get_with_path("/null")[:null]["my-filter".to_sym][:events][:in].value).to eq(events.size)
      end

      it "has not incremented :out" do
        subject.multi_filter(events)
        expect(collector.snapshot_metric.metric_store.get_with_path("/null")[:null]["my-filter".to_sym][:events][:out].value).to eq(0)
      end
    end

    context "when the filter create more events" do
      let(:plugin_klass) do
        Class.new(LogStash::Filters::Base) do
          config_name "super_plugin"
          config :host, :validate => :string
          def register; end
          def flush(options = {}); @events; end

          # naive split filter implementation
          def filter(event)
            event.cancel
            2.times { yield LogStash::Event.new }
          end
        end
      end

      before do
        allow(metric).to receive(:increment).with(anything, anything)
      end

      it "increments the in/out of the metric" do
        subject.multi_filter(events)
        event_metrics = collector.snapshot_metric.metric_store.get_with_path("/null")[:null]["my-filter".to_sym][:events]
        expect(event_metrics[:in].value).to eq(events.size)
        expect(event_metrics[:out].value).to eq(2 * events.size)
      end
    end
  end

  context "when the plugin doesnt support flush" do
    let(:plugin_klass) do
      Class.new(LogStash::Filters::Base) do
        config_name "super_plugin"
        config :host, :validate => :string
        def register; end

        def filter(event)
          event
        end
      end
    end

    before do
      allow(metric).to receive(:increment).with(anything, anything)
    end

    it "doesnt define a flush method" do
      expect(subject.has_flush).to be_falsey
    end

    it "increments the in/out of the metric" do
      subject.multi_filter(events)
      event_metrics = collector.snapshot_metric.metric_store.get_with_path("/null")[:null]["my-filter".to_sym][:events]
      expect(event_metrics[:in].value).to eq(events.size)
      expect(event_metrics[:out].value).to eq(events.size)
    end
  end

  context "#config_name" do
    it "proxy the config_name to the class method" do
      expect(subject.config_name).to eq("super_plugin")
    end
  end
end
