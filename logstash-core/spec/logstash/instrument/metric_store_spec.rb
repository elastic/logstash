# encoding: utf-8
require "logstash/instrument/metric_store"
require "logstash/instrument/metric_type/base"

describe LogStash::Instrument::MetricStore do
  let(:namespaces) { [ :root, :pipelines, :pipeline_01 ] }
  let(:key) { :events_in }
  let(:counter) { LogStash::Instrument::MetricType::Counter.new(namespaces, key) }

  context "when the metric object doesn't exist" do
    it "store the object" do
      expect(subject.fetch_or_store(namespaces, key, counter)).to eq(counter)
    end

    it "support a block as argument" do
      expect(subject.fetch_or_store(namespaces, key) { counter }).to eq(counter)
    end
  end

  context "when the metric object exist in the namespace"  do
    let(:new_counter) { LogStash::Instrument::MetricType::Counter.new(namespaces, key) }

    it "return the object" do
      subject.fetch_or_store(namespaces, key, counter)
      expect(subject.fetch_or_store(namespaces, key, new_counter)).to eq(counter)
    end
  end

  context "when the namespace end node isn't a map" do
    let(:conflicting_namespaces) { [:root, :pipelines, :pipeline_01, :events_in] }

    it "raise an exception" do
      subject.fetch_or_store(namespaces, key, counter)
      expect { subject.fetch_or_store(conflicting_namespaces, :new_key, counter) }.to raise_error(LogStash::Instrument::MetricStore::NamespacesExpectedError)
    end
  end

  context "retrieving events" do
    let(:metric_events) {
      [
        [[:node, :sashimi, :pipelines, :pipeline01, :plugins, :"logstash-output-elasticsearch"], :event_in, :increment],
        [[:node, :sashimi, :pipelines, :pipeline01], :processed_events_in, :increment],
        [[:node, :sashimi, :pipelines, :pipeline01], :processed_events_out, :increment],
      ]
    }

    before :each do
      # Lets add a few metrics in the store before trying to find them
      metric_events.each do |namespaces, metric_key, action|
        metric = subject.fetch_or_store(namespaces, metric_key, LogStash::Instrument::MetricType::Counter.new(namespaces, key))
        metric.execute(action)
      end
    end

    describe "#get" do
      it "retrieves end of of a branch" do
        metrics = subject.get(:node, :sashimi, :pipelines, :pipeline01, :plugins, :"logstash-output-elasticsearch")
        expect(metrics).to be_kind_of(Concurrent::Map)
      end

      it "retrieves branch" do
        metrics = subject.get(:node, :sashimi, :pipelines, :pipeline01)
        expect(metrics).to be_kind_of(Concurrent::Map)
      end

      it "allow to retrieve a specific metrics" do
        metrics = subject.get(:node, :sashimi, :pipelines, :pipeline01, :plugins, :"logstash-output-elasticsearch", :event_in)
        expect(metrics).to be_kind_of(LogStash::Instrument::MetricType::Base)
      end
    end

    describe "#each" do
      it "retrieves all the metric" do
        expect(subject.each.size).to eq(metric_events.size)
      end

      it "returns metric types" do
        subject.each do |metric_type|
          expect(metric_type).be kind_of(LogStash::Instrument::MetricType::Base)
        end
      end
    end
  end
end
