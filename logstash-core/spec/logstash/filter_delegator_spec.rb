# encoding: utf-8
require "spec_helper"
require "logstash/filter_delegator"
require "logstash/event"
require "support/shared_contexts"

describe LogStash::FilterDelegator do

  class MockGauge
    def increment(_)
    end
  end

  include_context "execution_context"

  let(:filter_id) { "my-filter" }
  let(:config) do
    { "host" => "127.0.0.1", "id" => filter_id }
  end
  let(:counter_in) { MockGauge.new }
  let(:counter_out) { MockGauge.new }
  let(:counter_time) { MockGauge.new }
  let(:metric) { LogStash::Instrument::NamespacedNullMetric.new(nil, :null) }
  let(:events) { [LogStash::Event.new, LogStash::Event.new] }

  before :each do
    allow(pipeline).to receive(:id).and_return(pipeline_id)
    allow(metric).to receive(:namespace).with(anything).and_return(metric)
    allow(metric).to receive(:counter).with(:in).and_return(counter_in)
    allow(metric).to receive(:counter).with(:out).and_return(counter_out)
    allow(metric).to receive(:counter).with(:duration_in_millis).and_return(counter_time)
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
      expect(subject.respond_to?(:flush)).to be_truthy
    end

    context "when the flush return events" do
      it "increments the out" do
        subject.multi_filter([LogStash::Event.new])
        expect(counter_out).to receive(:increment).with(1)
        subject.flush({})
      end
    end

    context "when the flush doesn't return anything" do
      it "doesnt increment the out" do
        expect(metric).not_to receive(:increment)
        subject.flush({})
      end
    end

    context "when the filter buffer events" do
      before do
        allow(metric).to receive(:increment).with(anything, anything)
      end

      it "has incremented :in" do
        expect(counter_in).to receive(:increment).with(events.size)
        subject.multi_filter(events)
      end

      it "has not incremented :out" do
        expect(counter_out).not_to receive(:increment).with(anything)
        subject.multi_filter(events)
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

      before do
        allow(metric).to receive(:increment).with(anything, anything)
      end

      it "increments the in/out of the metric" do
        expect(counter_in).to receive(:increment).with(events.size)
        expect(counter_out).to receive(:increment).with(events.size * 2)

        subject.multi_filter(events)
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
      expect(subject.respond_to?(:flush)).to be_falsey
    end

    it "increments the in/out of the metric" do
      expect(counter_in).to receive(:increment).with(events.size)
      expect(counter_out).to receive(:increment).with(events.size)

      subject.multi_filter(events)
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
