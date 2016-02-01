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
        [[:node, :sashimi, :pipelines, :pipeline02], :processed_events_out, :increment],
      ]
    }

    before :each do
      # Lets add a few metrics in the store before trying to find them
      metric_events.each do |namespaces, metric_key, action|
        metric = subject.fetch_or_store(namespaces, metric_key, LogStash::Instrument::MetricType::Counter.new(namespaces, metric_key))
        metric.execute(action)
      end
    end

    describe "#get" do
      context "when the path exist" do
        it "retrieves end of of a branch" do
          metrics = subject.get(:node, :sashimi, :pipelines, :pipeline01, :plugins, :"logstash-output-elasticsearch")
          expect(metrics).to match(a_hash_including(:node => a_hash_including(:sashimi => a_hash_including(:pipelines  => a_hash_including(:pipeline01 => a_hash_including(:plugins => a_hash_including(:"logstash-output-elasticsearch" => anything)))))))
        end

        it "retrieves branch" do
          metrics = subject.get(:node, :sashimi, :pipelines, :pipeline01)
          expect(metrics).to match(a_hash_including(:node => a_hash_including(:sashimi => a_hash_including(:pipelines  => a_hash_including(:pipeline01 => anything)))))
        end

        it "allow to retrieve a specific metrics" do
          metrics = subject.get(:node, :sashimi, :pipelines, :pipeline01, :plugins, :"logstash-output-elasticsearch", :event_in)
          expect(metrics).to match(a_hash_including(:node => a_hash_including(:sashimi => a_hash_including(:pipelines  => a_hash_including(:pipeline01 => a_hash_including(:plugins => a_hash_including(:"logstash-output-elasticsearch" => a_hash_including(:event_in => be_kind_of(LogStash::Instrument::MetricType::Base)))))))))
        end

        context "with filtered keys" do
          it "allows to retrieve multiple keys on the same level" do
            metrics = subject.get(:node, :sashimi, :pipelines, :"pipeline01,pipeline02")
            expect(metrics).to match(a_hash_including(:node => a_hash_including(:sashimi => a_hash_including(:pipelines  => a_hash_including(:pipeline01 => anything, :pipeline02 => anything)))))
          end

          it "supports space in the keys" do
            metrics = subject.get(:node, :sashimi, :pipelines, :"pipeline01, pipeline02 ")
            expect(metrics).to match(a_hash_including(:node => a_hash_including(:sashimi => a_hash_including(:pipelines  => a_hash_including(:pipeline01 => anything, :pipeline02 => anything)))))
          end

          it "retrieves only the requested keys" do
            metrics = subject.get(:node, :sashimi, :pipelines, :"pipeline01,pipeline02", :processed_events_in)
            expect(metrics[:node][:sashimi][:pipelines].keys).to include(:pipeline01, :pipeline02)
          end
        end

        context "when the path doesnt exist" do
          it "raise an exception" do
            expect { subject.get(:node, :sashimi, :dontexist) }.to raise_error(LogStash::Instrument::MetricStore::MetricNotFound, /dontexist/)
          end
        end
      end

      describe "#get_with_path" do
        context "when the path exist" do
          it "removes the first `/`" do
            metrics = subject.get_with_path("/node/sashimi/")
            expect(metrics).to match(a_hash_including(:node => a_hash_including(:sashimi => anything)))
          end

          it "retrieves end of of a branch" do
            metrics = subject.get_with_path("node/sashimi/pipelines/pipeline01/plugins/logstash-output-elasticsearch")
            expect(metrics).to match(a_hash_including(:node => a_hash_including(:sashimi => a_hash_including(:pipelines  => a_hash_including(:pipeline01 => a_hash_including(:plugins => a_hash_including(:"logstash-output-elasticsearch" => anything)))))))
          end

          it "retrieves branch" do
            metrics = subject.get_with_path("node/sashimi/pipelines/pipeline01")
            expect(metrics).to match(a_hash_including(:node => a_hash_including(:sashimi => a_hash_including(:pipelines  => a_hash_including(:pipeline01 => anything)))))
          end

          it "allow to retrieve a specific metrics" do
            metrics = subject.get_with_path("node/sashimi/pipelines/pipeline01/plugins/logstash-output-elasticsearch/event_in")
            expect(metrics).to match(a_hash_including(:node => a_hash_including(:sashimi => a_hash_including(:pipelines  => a_hash_including(:pipeline01 => a_hash_including(:plugins => a_hash_including(:"logstash-output-elasticsearch" => a_hash_including(:event_in => be_kind_of(LogStash::Instrument::MetricType::Base)))))))))
          end

          context "with filtered keys" do
            it "allows to retrieve multiple keys on the same level" do
              metrics = subject.get_with_path("node/sashimi/pipelines/pipeline01,pipeline02/plugins/logstash-output-elasticsearch/event_in")
              expect(metrics).to match(a_hash_including(:node => a_hash_including(:sashimi => a_hash_including(:pipelines  => a_hash_including(:pipeline01 => anything, :pipeline02 => anything)))))
            end

            it "supports space in the keys" do
              metrics = subject.get_with_path("node/sashimi/pipelines/pipeline01, pipeline02 /plugins/logstash-output-elasticsearch/event_in")
              expect(metrics).to match(a_hash_including(:node => a_hash_including(:sashimi => a_hash_including(:pipelines  => a_hash_including(:pipeline01 => anything, :pipeline02 => anything)))))
            end

            it "retrieves only the requested keys" do
              metrics = subject.get(:node, :sashimi, :pipelines, :"pipeline01,pipeline02", :processed_events_in)
              expect(metrics[:node][:sashimi][:pipelines].keys).to include(:pipeline01, :pipeline02)
            end
          end
        end
      end

      context "when the path doesnt exist" do
        it "raise an exception" do
          expect { subject.get_with_path("node/sashimi/dontexist, pipeline02 /plugins/logstash-output-elasticsearch/event_in") }.to raise_error(LogStash::Instrument::MetricStore::MetricNotFound, /dontexist/)
        end
      end
    end

    describe "#each" do
      it "retrieves all the metric" do
        expect(subject.each.size).to eq(metric_events.size)
      end

      it "returns metric types" do
        metrics = []
        subject.each { |i| metrics << i }
        expect(metrics.size).to eq(metric_events.size)
      end

      it "retrieves all the metrics from a specific branch" do
        metrics = []
        subject.each("node/sashimi/pipelines/pipeline01") { |i| metrics << i }
        expect(metrics.size).to eq(3)
      end
    end
  end
end
