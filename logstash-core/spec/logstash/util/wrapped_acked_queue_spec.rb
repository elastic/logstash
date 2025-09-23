# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "spec_helper"

describe LogStash::WrappedAckedQueue do
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
      batch = queue.read_batch(1, 250).to_java
      expect(batch.size()).to eq(1)

      expect(queue.is_empty?).to be_falsey
    end

    it "is_empty? when all elements are acked" do
      queue.push(LogStash::Event.new)
      batch = queue.read_batch(1, 250).to_java
      expect(batch.size()).to eq(1)
      expect(queue.is_empty?).to be_falsey
      batch.close
      expect(queue.is_empty?).to be_truthy
    end
  end

  context "persisted" do
    let(:page_capacity) { 1024 }
    let(:max_events) { 0 }
    let(:max_bytes) { 0 }
    let(:checkpoint_acks) { 1024 }
    let(:checkpoint_writes) { 1024 }
    let(:path) { Stud::Temporary.directory }

    let(:queue_settings) do
      LogStash::AckedQueue.file_settings_builder(path)
                          .capacity(page_capacity)
                          .maxUnread(max_events)
                          .checkpointMaxAcks(checkpoint_acks)
                          .checkpointMaxWrites(checkpoint_writes)
                          .queueMaxBytes(max_bytes)
                          .build
    end

    let(:queue) { LogStash::WrappedAckedQueue.new(queue_settings, org.logstash.ackedqueue.QueueFactoryExt::BatchMetricMode::DISABLED) }

    after do
      queue.close
    end

    include_examples "queue tests"
  end
end
