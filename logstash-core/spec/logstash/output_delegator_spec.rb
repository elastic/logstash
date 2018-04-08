# encoding: utf-8
require "logstash/execution_context"
require "spec_helper"
require "support/shared_contexts"
require "logstash/output_delegator_strategy_registry"
require "logstash/output_delegator_strategies/shared"
require "logstash/output_delegator_strategies/single"
require "logstash/output_delegator_strategies/legacy"

describe LogStash::OutputDelegator do

  let(:events) { 7.times.map { LogStash::Event.new }}
  let(:plugin_args) { {"id" => "foo", "arg1" => "val1"} }
  let(:metric) {
    LogStash::Instrument::NamespacedMetric.new(
      LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new), [:output]
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

  include_context "execution_context"

  subject { described_class.new(out_klass, metric, execution_context, ::LogStash::OutputDelegatorStrategyRegistry.instance, plugin_args) }

  context "with a plain output plugin" do
    let(:out_klass) { double("output klass") }
    let(:out_inst) { double("output instance") }
    let(:concurrency) { :single }

    before(:each) do
      # use the same metric instance
      allow(out_klass).to receive(:new).with(plugin_args).and_return(out_inst)
      allow(out_klass).to receive(:name).and_return("example")
      allow(out_klass).to receive(:concurrency).with(any_args).and_return concurrency
      allow(out_klass).to receive(:config_name).and_return("dummy_plugin")
      allow(out_inst).to receive(:register)
      allow(out_inst).to receive(:multi_receive)
      allow(out_inst).to receive(:metric=).with(any_args)
      allow(out_inst).to receive(:execution_context=).with(execution_context)
      allow(out_inst).to receive(:id).and_return("a-simple-plugin")
    end

    it "should initialize cleanly" do
      expect { subject }.not_to raise_error
    end

    it "should push the name of the plugin to the metric" do
      described_class.new(out_klass, metric, execution_context, ::LogStash::OutputDelegatorStrategyRegistry.instance, plugin_args)
      expect(metric.collector.snapshot_metric.metric_store.get_with_path("output/foo")[:output][:foo][:name].value).to eq(out_klass.config_name)
    end

    context "after having received a batch of events" do
      before do
        subject.register
      end

      it "should pass the events through" do
        expect(out_inst).to receive(:multi_receive).with(events)
        subject.multi_receive(events)
      end

      it "should increment the number of events received" do
        subject.multi_receive(events)
        store = metric.collector.snapshot_metric.metric_store.get_with_path("output/foo")[:output][:foo][:events]
        number_of_events = events.length
        expect(store[:in].value).to eq(number_of_events)
        expect(store[:out].value).to eq(number_of_events)
      end

      it "should record the `duration_in_millis`" do
        value = 0
        while value == 0
          subject.multi_receive(events)
          store = metric.collector.snapshot_metric.metric_store.get_with_path("output/foo")[:output][:foo][:events]
          value = store[:duration_in_millis].value
        end
        expect(value).to be > 0
      end
    end

    describe "closing" do
      before do
        subject.register
      end

      it "should register the output plugin instance on register" do
        expect(out_inst).to have_received(:register)
      end

      it "should close the output plugin instance when closing" do
        expect(out_inst).to receive(:do_close)
        subject.do_close
      end
    end

    describe "concurrency strategies" do
      it "should have :single as the default" do
        expect(subject.concurrency).to eq :single
      end

      [
        [:shared, ::LogStash::OutputDelegatorStrategies::Shared],
        [:single, ::LogStash::OutputDelegatorStrategies::Single],
        [:legacy, ::LogStash::OutputDelegatorStrategies::Legacy],
      ].each do |strategy_concurrency,klass|
        context "with strategy #{strategy_concurrency}" do
          let(:concurrency) { strategy_concurrency }

          it "should find the correct concurrency type for the output" do
            expect(subject.concurrency).to eq(strategy_concurrency)
          end

          it "should find the correct Strategy class for the worker" do
            expect(subject.strategy).to be_a(klass)
          end

          it "should set the metric on the instance" do
            expect(out_inst).to have_received(:metric=).with(subject.namespaced_metric)
          end

          [[:register], [:do_close], [:multi_receive, [[]] ] ].each do |method, args|
            context "strategy objects" do
              before do
                allow(subject.strategy).to receive(method)
              end

              it "should delegate #{method} to the strategy" do
                subject.send(method, *args)
                if args
                  expect(subject.strategy).to have_received(method).with(*args)
                else
                  expect(subject.strategy).to have_received(method).with(no_args)
                end
              end
            end

            context "strategy output instances" do
              before do
                allow(out_inst).to receive(method)
              end

              it "should delegate #{method} to the strategy" do
                subject.send(method, *args)
                if args
                  expect(out_inst).to have_received(method).with(*args)
                else
                  expect(out_inst).to have_received(method).with(no_args)
                end
              end
            end
          end
        end
      end
    end
  end
end
