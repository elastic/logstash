# encoding: utf-8
require "spec_helper"
require "logstash/filter_delegator"
require "logstash/instrument/null_metric"
require "logstash/event"

describe LogStash::FilterDelegator do
  let(:logger) { double(:logger) }
  let(:filter_id) { "my-filter" }
  let(:config) do
    { "host" => "127.0.0.1", "id" => filter_id }
  end
  let(:metric) { LogStash::Instrument::NullMetric.new }
  let(:events) { [LogStash::Event.new, LogStash::Event.new] }

  before :each do
    allow(metric).to receive(:namespace).with(anything).and_return(metric)
  end

  let(:plugin_klass) do
    Class.new(LogStash::Filters::Base) do
      config_name "super_plugin"
      config :host, :validate => :string
      def register; end
    end
  end

  subject { described_class.new(logger, plugin_klass, metric, config) }

  it "create a plugin with the passed options" do
    expect(plugin_klass).to receive(:new).with(config).and_return(plugin_klass.new(config))
    described_class.new(logger, plugin_klass, metric, config)
  end

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
        expect(metric).to receive(:increment).with(:out, 1)
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
        expect(metric).to receive(:increment).with(:in, events.size)
        subject.multi_filter(events)
      end

      it "has not incremented :out" do
        expect(metric).not_to receive(:increment).with(:out, anything)
        subject.multi_filter(events)
      end
    end

    context "when the fitler create more events" do
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
        expect(metric).to receive(:increment).with(:in, events.size)
        expect(metric).to receive(:increment).with(:out, events.size * 2)

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
      expect(metric).to receive(:increment).with(:in, events.size)
      expect(metric).to receive(:increment).with(:out, events.size)

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
