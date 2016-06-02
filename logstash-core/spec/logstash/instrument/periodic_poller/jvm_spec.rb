# encoding: utf-8
require "spec_helper"
require "logstash/instrument/periodic_poller/jvm"
require "logstash/instrument/collector"

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
      subject(:jvm_metrics) { snapshot_store.get_shallow(:jvm, :process) }

      # Make looking up metric paths easy when given varargs of keys
      # e.g. mval(:parent, :child)
      def mval(*metric_path)
        metric_path.reduce(jvm_metrics) {|acc,k| acc[k]}.value
      end          

      [
        :max_file_descriptors,
        :open_file_descriptors,
        :peak_open_file_descriptors,
        [:mem, :total_virtual_in_bytes],
        [:cpu, :total_in_millis],
        [:cpu, :percent]
      ].each do |path|
        path = Array(path)
        it "should have a value for #{path} that is Numeric" do
          expect(mval(*path)).to be_a(Numeric)
        end
      end
    end
  end
end
