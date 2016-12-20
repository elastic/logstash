# encoding: utf-8
require "spec_helper"
require "logstash/instrument/periodic_poller/jvm"
require "logstash/instrument/collector"
require "logstash/environment"

describe LogStash::Instrument::PeriodicPoller::JVM::GarbageCollectorName do
  subject { LogStash::Instrument::PeriodicPoller::JVM::GarbageCollectorName }

  context "when the gc is of young type" do
    LogStash::Instrument::PeriodicPoller::JVM::GarbageCollectorName::YOUNG_GC_NAMES.each do |name|
      it "returns young for #{name}" do
        expect(subject.get(name)).to eq(:young)
      end
    end
  end

  context "when the gc is of old type" do
    LogStash::Instrument::PeriodicPoller::JVM::GarbageCollectorName::OLD_GC_NAMES.each do |name|
      it "returns old for #{name}" do
        expect(subject.get(name)).to eq(:old)
      end
    end
  end

  it "returns `nil` when we dont know the gc name" do
      expect(subject.get("UNKNOWN GC")).to be_nil
  end
end


describe LogStash::Instrument::PeriodicPoller::JVM do
  let(:metric) { LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new) }
  let(:options) { {} }
  subject(:jvm) { described_class.new(metric, options) }

  it "should initialize cleanly" do
    expect { jvm }.not_to raise_error
  end

  describe "load average" do
    context "on linux" do
      context "when an exception occur reading the file" do
        before do
          expect(LogStash::Environment).to receive(:windows?).and_return(false)
          expect(LogStash::Environment).to receive(:linux?).and_return(true)
          expect(::File).to receive(:read).with("/proc/loadavg").and_raise("Didnt work out so well")
        end

        it "doesn't raise an exception" do
          expect { subject.collect }.not_to raise_error
        end
      end
    end
  end

  describe "collections" do
    subject(:collection) { jvm.collect }
    it "should run cleanly" do
      expect { collection }.not_to raise_error
    end

    describe "metrics" do
      before(:each) { jvm.collect }
      let(:snapshot_store) { metric.collector.snapshot_metric.metric_store }
      subject(:jvm_metrics) { snapshot_store.get_shallow(:jvm) }

      # Make looking up metric paths easy when given varargs of keys
      # e.g. mval(:parent, :child)
      def mval(*metric_path)
        metric_path.reduce(jvm_metrics) {|acc,k| acc[k]}.value
      end

      [
        [:process, :max_file_descriptors],
        [:process, :open_file_descriptors],
        [:process, :peak_open_file_descriptors],
        [:process, :mem, :total_virtual_in_bytes],
        [:process, :cpu, :total_in_millis],
        [:process, :cpu, :percent],
        [:gc, :collectors, :young, :collection_count],
        [:gc, :collectors, :young, :collection_time_in_millis],
        [:gc, :collectors, :old, :collection_count],
        [:gc, :collectors, :old, :collection_time_in_millis]
      ].each do |path|
        path = Array(path)
        it "should have a value for #{path} that is Numeric" do
          expect(mval(*path)).to be_a(Numeric)
        end
      end

      context "real system" do
        if LogStash::Environment.linux?
          context "Linux" do
            it "returns the load avg" do
              expect(subject[:process][:cpu][:load_average].value).to include(:"1m" => a_kind_of(Numeric), :"5m" => a_kind_of(Numeric), :"15m" => a_kind_of(Numeric))
            end
          end
        elsif LogStash::Environment.windows?
          context "Window" do
            it "returns nothing" do
              expect(subject[:process][:cpu].has_key?(:load_average)).to be_falsey
            end
          end
        else
          context "Other" do
            it "returns 1m only" do
              expect(subject[:process][:cpu][:load_average].value).to include(:"1m" => a_kind_of(Numeric))
            end
          end
        end
      end
    end
  end
end
