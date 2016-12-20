# encoding: utf-8
require "logstash/output_delegator"
require 'spec_helper'

describe LogStash::OutputDelegator do
  let(:logger) { double("logger") }
  let(:events) { 7.times.map { LogStash::Event.new }}
  let(:plugin_args) { {"id" => "foo", "arg1" => "val1"} }
  let(:collector) { [] }
  let(:metric) { LogStash::Instrument::NamespacedNullMetric.new(collector, :null) }

  subject { described_class.new(logger, out_klass, metric, ::LogStash::OutputDelegatorStrategyRegistry.instance, plugin_args) }

  context "with a plain output plugin" do
    let(:out_klass) { double("output klass") }
    let(:out_inst) { double("output instance") }
    let(:concurrency) { :single }

    before(:each) do
      # use the same metric instance
      allow(metric).to receive(:namespace).with(any_args).and_return(metric)

      allow(out_klass).to receive(:new).with(any_args).and_return(out_inst)
      allow(out_klass).to receive(:name).and_return("example")
      allow(out_klass).to receive(:concurrency).with(any_args).and_return concurrency
      allow(out_klass).to receive(:config_name).and_return("dummy_plugin")
      allow(out_inst).to receive(:register)
      allow(out_inst).to receive(:multi_receive)
      allow(out_inst).to receive(:metric=).with(any_args)
      allow(out_inst).to receive(:id).and_return("a-simple-plugin")

      allow(subject.metric_events).to receive(:increment).with(any_args)
      allow(logger).to receive(:debug).with(any_args)
    end

    it "should initialize cleanly" do
      expect { subject }.not_to raise_error
    end

    it "should push the name of the plugin to the metric" do
      expect(metric).to receive(:gauge).with(:name, out_klass.config_name)
      described_class.new(logger, out_klass, metric, ::LogStash::OutputDelegatorStrategyRegistry.instance, plugin_args)
    end

    context "after having received a batch of events" do
      before do
        subject.register
        subject.multi_receive(events)
      end

      it "should pass the events through" do
        expect(out_inst).to have_received(:multi_receive).with(events)
      end

      it "should increment the number of events received" do
        expect(subject.metric_events).to have_received(:increment).with(:in, events.length)
        expect(subject.metric_events).to have_received(:increment).with(:out, events.length)
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

          it "should set the correct parameters on the instance" do
            expect(out_klass).to have_received(:new).with(plugin_args)
          end

          it "should set the metric on the instance" do
            expect(out_inst).to have_received(:metric=).with(metric)
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
