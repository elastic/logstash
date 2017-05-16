# encoding: utf-8
require "spec_helper"

require "logstash/codecs/identity_map_codec"

class IdentityMapCodecTracer
  def initialize() @tracer = []; end
  def clone() self.class.new; end
  def decode(data) @tracer.push [:decode, data]; end
  def encode(event) @tracer.push [:encode, event]; end
  def flush(&block) @tracer.push [:flush, true]; end
  def close() @tracer.push [:close, true]; end

  def trace_for(symbol)
    params = @tracer.assoc(symbol)
    params.nil? ? false : params.last
  end
end

class LogTracer
  def initialize() @tracer = []; end
  def warn(*args) @tracer.push [:warn, args]; end
  def error(*args) @tracer.push [:error, args]; end

  def trace_for(symbol)
    params = @tracer.assoc(symbol)
    params.nil? ? false : params.last
  end
end

describe LogStash::Codecs::IdentityMapCodec do
  let(:codec)   { IdentityMapCodecTracer.new }
  let(:logger)  { LogTracer.new }
  let(:demuxer) { described_class.new(codec, logger) }
  let(:stream1) { "stream-a" }
  let(:codec1)  { demuxer.stream_codec(stream1) }
  let(:arg1)    { "data-a" }

  after do
    codec.close
  end

  describe "operating without stream identity" do
    let(:stream1) { nil }

    it "transparently refers to the original codec" do
      expect(codec).to eql(codec1)
    end
  end

  describe "operating with stream identity" do

    before { demuxer.decode(arg1, stream1) }

    it "the first identity refers to the original codec" do
      expect(codec).to eql(codec1)
    end
  end

  describe "#decode" do
    context "when no identity is used" do
      let(:stream1) { nil }

      it "calls the method on the original codec" do
        demuxer.decode(arg1, stream1)

        expect(codec.trace_for(:decode)).to eq(arg1)
      end
    end

    context "when multiple identities are used" do
      let(:stream2) { "stream-b" }
      let(:codec2) { demuxer.stream_codec(stream2) }
      let(:arg2)   { "data-b" }

      it "calls the method on the appropriate codec" do
        demuxer.decode(arg1, stream1)
        demuxer.decode(arg2, stream2)

        expect(codec1.trace_for(:decode)).to eq(arg1)
        expect(codec2.trace_for(:decode)).to eq(arg2)
      end
    end
  end

  describe "#encode" do
    context "when no identity is used" do
      let(:stream1) { nil }
      let(:arg1) { LogStash::Event.new({"type" => "file"}) }

      it "calls the method on the original codec" do
        demuxer.encode(arg1, stream1)

        expect(codec.trace_for(:encode)).to eq(arg1)
      end
    end

    context "when multiple identities are used" do
      let(:stream2) { "stream-b" }
      let(:codec2) { demuxer.stream_codec(stream2) }
      let(:arg2)   { LogStash::Event.new({"type" => "file"}) }

      it "calls the method on the appropriate codec" do
        demuxer.encode(arg1, stream1)
        demuxer.encode(arg2, stream2)

        expect(codec1.trace_for(:encode)).to eq(arg1)
        expect(codec2.trace_for(:encode)).to eq(arg2)
      end
    end
  end

  describe "#close" do
    context "when no identity is used" do
      before do
        demuxer.decode(arg1)
      end

      it "calls the method on the original codec" do
        demuxer.close
        expect(codec.trace_for(:close)).to be_truthy
      end
    end

    context "when multiple identities are used" do
      let(:stream2) { "stream-b" }
      let(:codec2) { demuxer.stream_codec(stream2) }
      let(:arg2)   { LogStash::Event.new({"type" => "file"}) }

      before do
        demuxer.decode(arg1, stream1)
        demuxer.decode(arg2, stream2)
      end

      it "calls the method on all codecs" do
        demuxer.close

        expect(codec1.trace_for(:close)).to be_truthy
        expect(codec2.trace_for(:close)).to be_truthy
      end
    end
  end

  describe "over capacity protection" do
    let(:demuxer) { described_class.new(codec, logger).max_identities(limit) }

    context "when capacity at 80% or higher" do
      let(:limit) { 10 }

      it "a warning is logged" do
        limit.pred.times do |i|
          demuxer.decode(Object.new, "stream#{i}")
        end

        expect(logger.trace_for(:warn).first).to match %r|has reached 80% capacity|
      end
    end

    context "when capacity is exceeded" do
      let(:limit) { 2 }
      let(:error_class) { LogStash::Codecs::IdentityMapCodec::IdentityMapUpperLimitException }

      it "an exception is raised" do
        limit.times do |i|
          demuxer.decode(Object.new, "stream#{i}")
        end
        expect { demuxer.decode(Object.new, "stream4") }.to raise_error(error_class)
      end

      context "initially but some streams are idle and can be evicted" do
        let(:demuxer) { described_class.new(codec, logger).max_identities(limit).evict_timeout(1) }

        it "an exception is NOT raised" do
          demuxer.decode(Object.new, "stream1")
          sleep(1.2)
          demuxer.decode(Object.new, "stream2")
          expect(demuxer.size).to eq(limit)
          expect { demuxer.decode(Object.new, "stream4") }.not_to raise_error
        end
      end
    end
  end

  describe "usage tracking" do
    let(:demuxer) { described_class.new(codec, logger).evict_timeout(10) }
    context "when an operation is performed by identity" do
      it "the new eviction time for that identity is recorded" do
        demuxer.decode(Object.new, "stream1")
        current_eviction = demuxer.usage_map["stream1"]
        sleep(2)
        demuxer.decode(Object.new, "stream1")
        expect(demuxer.usage_map["stream1"]).to be >= current_eviction + 2
      end
    end
  end

  describe "codec eviction" do
    let(:demuxer) { described_class.new(codec, logger).evict_timeout(1).cleaner_interval(1) }
    context "when an identity has become stale" do
      it "the cleaner evicts the codec" do
        demuxer.decode(Object.new, "stream1")
        sleep(2.1)
        expect(demuxer.identity_map.keys).not_to include("stream1")
      end
    end
  end
end
