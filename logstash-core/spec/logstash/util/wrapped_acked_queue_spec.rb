# encoding: utf-8
require "spec_helper"
require "logstash/util/wrapped_acked_queue"

describe LogStash::Util::WrappedAckedQueue do
  shared_examples "queue tests" do
    it "is_empty? on creation" do
      expect(queue.is_empty?).to be_truthy
    end

    it "not is_empty? after pushing an element" do
      queue.push(LogStash::Event.new)
      expect(queue.is_empty?).to be_falsey
    end

    it "not is_empty? when all elements are not acked" do
      queue.push(LogStash::Event.new)
      batch = queue.read_batch(1, 250)
      expect(batch.get_elements.size).to eq(1)
      expect(queue.is_empty?).to be_falsey
    end

    it "is_empty? when all elements are acked" do
      queue.push(LogStash::Event.new)
      batch = queue.read_batch(1, 250)
      expect(batch.get_elements.size).to eq(1)
      expect(queue.is_empty?).to be_falsey
      batch.close
      expect(queue.is_empty?).to be_truthy
    end
  end

  context "memory" do
    let(:page_capacity) { 1024 }
    let(:max_events) { 0 }
    let(:max_bytes) { 0 }
    let(:path) { Stud::Temporary.directory }
    let(:queue) { LogStash::Util::WrappedAckedQueue.create_memory_based(path, page_capacity, max_events, max_bytes) }

    after do
      queue.close
    end

    include_examples "queue tests"
  end

  context "persisted" do
    let(:page_capacity) { 1024 }
    let(:max_events) { 0 }
    let(:max_bytes) { 0 }
    let(:checkpoint_acks) { 1024 }
    let(:checkpoint_writes) { 1024 }
    let(:checkpoint_interval) { 0 }
    let(:path) { Stud::Temporary.directory }
    let(:queue) { LogStash::Util::WrappedAckedQueue.create_file_based(path, page_capacity, max_events, checkpoint_acks, checkpoint_writes, checkpoint_interval, max_bytes) }

    after do
      queue.close
    end

    include_examples "queue tests"
  end
end
