# encoding: utf-8
require "spec_helper"
require "logstash/filter_delegator"
require "logstash/event"
require "support/shared_contexts"

java_import org.logstash.RubyUtil

describe LogStash::JavaFilterDelegator do

  class MockGauge
    def increment(_)
    end
  end

  include_context "execution_context"

  let(:filter_id) { "my_filter" }
  let(:config) do
    { "host" => "127.0.0.1", "id" => filter_id }
  end
  let(:metric) {
    LogStash::Instrument::NamespacedMetric.new(
        LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new), [:filter]
    )
  }
  let(:counter_in) {
    counter = metric.counter(:in)
    counter.increment(0)
    counter
  }
  let(:counter_out) {
    counter = metric.counter(:out)
    counter.increment(0)
    counter
  }
  let(:counter_time) {
    counter = metric.counter(:duration_in_millis)
    counter.increment(0)
    counter
  }
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
        def flush(options = {}); @events ; end
        def filter(event)
          @events ||= []
          @events << event
          event.cancel
        end
      end
    end

    it "defines a flush method" do
      expect(subject.to_java.hasFlush).to be_truthy
    end

    context "when the flush return events" do
      it "increments the out" do
        subject.to_java.multiFilter([LogStash::Event.new])
        event_metrics = metric.collector.snapshot_metric.metric_store.get_with_path(
            "filter/my_filter"
        )[:filter][:my_filter][:events]
        expect(event_metrics[:out].value).to eq(0)
        subject.to_java.flush({})
        expect(event_metrics[:out].value).to eq(1)
      end
    end

    context "when the flush doesn't return anything" do
      it "doesnt increment the out" do
        subject.to_java.flush({})
        expect(
            metric.collector.snapshot_metric.metric_store.
                get_with_path("filter/my_filter")[:filter][:my_filter][:events][:duration_in_millis].value
        ).to eq(0)
      end
    end

    context "when the filter buffer events" do

      it "has incremented :in" do
        subject.to_java.multiFilter(events)
        expect(
            metric.collector.snapshot_metric.metric_store.
                get_with_path("filter/my_filter")[:filter][:my_filter][:events][:in].value
        ).to eq(events.size)
      end

      it "has not incremented :out" do
        subject.to_java.multiFilter(events)
        expect(
            metric.collector.snapshot_metric.metric_store.
                get_with_path("filter/my_filter")[:filter][:my_filter][:events][:out].value
        ).to eq(0)
      end
    end

    context "when the filter create more events" do
      let(:plugin_klass) do
        Class.new(LogStash::Filters::Base) do
          config_name "super_plugin"
          config :host, :validate => :string
          def register; end
          def flush(options = {}); @events ; end

          # naive split filter implementation
          def filter(event)
            event.cancel
            2.times { yield LogStash::Event.new }
          end
        end
      end

      it "increments the in/out of the metric" do
        subject.to_java.multiFilter(events)
        event_metrics = metric.collector.snapshot_metric.metric_store.get_with_path(
            "filter/my_filter"
        )[:filter][:my_filter][:events]
        expect(event_metrics[:in].value).to eq(events.size)
        expect(event_metrics[:out].value).to eq(events.size * 2)
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
      expect(subject.to_java.hasFlush).to be_falsey
    end

    it "increments the in/out of the metric" do
      subject.to_java.multiFilter(events)
      event_metrics = metric.collector.snapshot_metric.metric_store.get_with_path(
          "filter/my_filter"
      )[:filter][:my_filter][:events]
      expect(event_metrics[:in].value).to eq(events.size)
      expect(event_metrics[:out].value).to eq(events.size)
    end
  end

  context "#config_name" do
    it "proxy the config_name to the class method" do
      expect(subject.config_name).to eq("super_plugin")
    end
  end

  context "delegate methods to the original plugin" do
    # I am not testing the behavior of these methods
    # this is done in the plugin tests. I just want to make sure
    # the proxy delegates the methods.
    LogStash::FilterDelegator::DELEGATED_METHODS.each do |method|
      it "delegate method: `#{method}` to the filter" do
        expect(subject.respond_to?(method))
      end
    end
  end
end
