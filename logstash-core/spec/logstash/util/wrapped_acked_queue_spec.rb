# encoding: utf-8
require "spec_helper"
require "logstash/util/wrapped_acked_queue"
require "logstash/instrument/collector"

describe LogStash::Util::WrappedAckedQueue do
  let(:path) {Stud::Temporary.directory}
  let(:queue_capacity) {1024 ** 2}
  let(:queue) do
    described_class.create_file_based(path, queue_capacity / 2, 0, 1024, 1024, 1024, queue_capacity)
  end

  context "ReadClient #empty?" do
    it "returns true for an empty queue" do
      expect(queue.read_client.empty?).to be_truthy
    end
  end
end
