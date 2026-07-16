# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require "helpers/elasticsearch_client_holder"
require "logstash/ssl_file_tracker"

describe LogStash::Helpers::ElasticsearchClientHolder do
  let(:tracker) { instance_double(LogStash::SslFileTracker) }
  let(:tracking_id) { :".cpm" }
  let(:factory_calls) { [] }
  let(:factory) { ->() { factory_calls << :built; double("client", close: nil) } }
  subject(:es_client_holder) { described_class.create(tracker, tracking_id, &factory) }

  describe "#initialize" do
    it "raises when no factory block is given" do
      expect { described_class.create(tracker, :".cpm") }
        .to raise_error(ArgumentError, /client_factory block is required/)
    end
  end

  describe "::create" do
    shared_examples "without factory block" do
      it "fails helpfully when no factory block is provided" do
        expect { described_class.create(tracker, tracking_id) }
          .to raise_error(ArgumentError, /client_factory block is required/)
      end
    end

    context "when no tracker is given" do
      let(:tracker) { nil }
      it "returns a Lazy instance" do
        client_holder = described_class.create(tracker, tracking_id, &factory)
        expect(client_holder).to be_a_kind_of LogStash::Helpers::ElasticsearchClientHolder
        expect(client_holder).to be_a_kind_of LogStash::Helpers::ElasticsearchClientHolder::Lazy
      end
      include_examples "without factory block"
    end

    context "when a tracker and id are both given" do
      it "returns an SslRebuildable instance with the provided tracker and id" do
        client_holder = described_class.create(tracker, tracking_id, &factory)
        expect(client_holder).to be_a_kind_of LogStash::Helpers::ElasticsearchClientHolder
        expect(client_holder).to be_a_kind_of LogStash::Helpers::ElasticsearchClientHolder::SslRebuildable
        expect(client_holder.tracker).to eq(tracker)
        expect(client_holder.id).to eq(tracking_id)
      end

      include_examples "without factory block"
    end

    context "when `tracker` is provided and `id` is not" do
      let(:tracking_id) { nil }
      it "fails helpfully" do
        expect { described_class.create(tracker, tracking_id) }.to raise_error(ArgumentError, /id is required/)
      end
    end
  end

  shared_examples "#get memoization" do
    it "lazily calls the factory once and caches the result" do
      es_client_holder
      expect(factory_calls.size).to eq(0)
      first = es_client_holder.get
      second = es_client_holder.get
      expect(factory_calls.size).to eq(1)
      expect(second).to be(first)
    end
  end

  describe "Lazy implementation" do
    let(:es_client_holder) { described_class::Lazy.new(&factory) }

    describe "#get" do
      include_examples "#get memoization"
    end
  end

  describe "SslRebuildable implementation" do
    let(:es_client_holder) { described_class::SslRebuildable.new(tracker, tracking_id, &factory) }

    describe "#get" do
      before(:each) do
        # mimic tracking behaviour when the id has NOT been marked stale
        allow(tracker).to receive(:consume_stale).with(tracking_id).and_return(nil)
      end
      include_examples "#get memoization"

      it "reloads the client when it has been invalidated" do
        existing = es_client_holder.get
        expect(existing).to receive(:close)

        # mimic tracker behaviour when the id has been marked stale
        allow(tracker).to receive(:consume_stale).with(tracking_id).and_yield

        expect do
          fresh = es_client_holder.get
          expect(fresh).to_not be(existing)
        end.to change { factory_calls.size }.by(1)
      end
    end
  end
end
