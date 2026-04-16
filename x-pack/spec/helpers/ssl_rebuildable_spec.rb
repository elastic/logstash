# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require "helpers/ssl_rebuildable"
require "logstash/ssl_file_tracker"

describe LogStash::Helpers::SslRebuildable do
  let(:tracker) { instance_double(LogStash::SslFileTracker) }
  let(:factory_calls) { [] }
  let(:factory) { ->() { factory_calls << :built; double("client", close: nil) } }
  subject(:rebuildable) { described_class.new(tracker, :".cpm", &factory) }

  describe "#initialize" do
    it "raises when no factory block is given" do
      expect { described_class.new(tracker, :".cpm") }
        .to raise_error(ArgumentError, /client_factory block is required/)
    end
  end

  describe "#client" do
    it "lazily calls the factory once and caches the result" do
      first = rebuildable.client
      second = rebuildable.client
      expect(factory_calls.size).to eq(1)
      expect(second).to be(first)
    end
  end

  describe "#maybe_rebuild" do
    it "delegates to tracker.consume_stale with the configured id" do
      expect(tracker).to receive(:consume_stale).with(:".cpm").and_return(false)
      rebuildable.maybe_rebuild
    end

    it "closes the existing client and eagerly builds a fresh one when stale" do
      allow(tracker).to receive(:consume_stale).with(:".cpm").and_yield
      existing = rebuildable.client
      expect(existing).to receive(:close)
      rebuildable.maybe_rebuild
      expect(factory_calls.size).to eq(2)
      fresh = rebuildable.client
      expect(fresh).not_to be(existing)
    end

    it "is a no-op when the tracker is nil" do
      untracked = described_class.new(nil, nil, &factory)
      expect(untracked.maybe_rebuild).to eq(false)
    end

    it "coerces string ids to symbol" do
      r = described_class.new(tracker, ".cpm", &factory)
      expect(tracker).to receive(:consume_stale).with(:".cpm")
      r.maybe_rebuild
    end
  end

  describe "#invalidate" do
    it "closes and clears the cached client" do
      existing = rebuildable.client
      expect(existing).to receive(:close)
      rebuildable.send(:invalidate)
      expect(rebuildable.client).not_to be(existing)
    end

    it "logs and clears when close raises" do
      failing = double("client")
      allow(failing).to receive(:close).and_raise(StandardError, "boom")
      rebuildable.instance_variable_set(:@client, failing)
      expect(rebuildable.logger).to receive(:warn).with(/Error closing stale ES client/, hash_including(:message))
      rebuildable.send(:invalidate)
      expect(rebuildable.instance_variable_get(:@client)).to be_nil
    end

    it "is safe when no client has been built yet" do
      expect { rebuildable.send(:invalidate) }.not_to raise_error
    end
  end
end
