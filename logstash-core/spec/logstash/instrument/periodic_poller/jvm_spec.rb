# encoding: utf-8
require "spec_helper"
require "logstash/instrument/periodic_poller/jvm"
require "logstash/instrument/collector"

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
    end
  end
end
