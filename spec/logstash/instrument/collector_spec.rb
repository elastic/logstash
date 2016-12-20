# encoding: utf-8
require "logstash/instrument/collector"
require "spec_helper"

describe LogStash::Instrument::Collector do
  subject { LogStash::Instrument::Collector.new }
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

  describe "#snapshot_metric" do
    it "return a `LogStash::Instrument::MetricStore`" do
      expect(subject.snapshot_metric).to be_kind_of(LogStash::Instrument::Snapshot)
    end
  end
end
