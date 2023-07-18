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
require "logstash/instrument/collector"

describe LogStash::WrappedSynchronousQueue do
  subject {LogStash::WrappedSynchronousQueue.new(5)}

  describe "queue clients" do
    context "when requesting a write client" do
      it "returns a client" do
        expect(subject.write_client).to be_a(LogStash::MemoryWriteClient)
      end
    end

    context "when requesting a read client" do
      it "returns a client" do
        expect(subject.read_client).to be_a(LogStash::MemoryReadClient)
      end
    end

    describe "WriteClient | ReadClient" do
      let(:write_client) { subject.write_client }
      let(:read_client)  { subject.read_client }

      context "when writing to the queue" do
        before :each do
          read_client.set_events_metric(LogStash::Instrument::NamespacedNullMetric.new(nil, :null))
          read_client.set_pipeline_metric(LogStash::Instrument::NamespacedNullMetric.new(nil, :null))
        end

        it "appends batches to the queue" do
          batch = []
          messages = []
          5.times do |i|
            message = "value-#{i}"
            batch.push(LogStash::Event.new({"message" => message}))
            messages << message
          end
          write_client.push_batch(batch)
          read_batch = read_client.read_batch.to_java
          expect(read_batch.filteredSize).to eq(5)
          read_batch.to_a.each do |data|
            message = data.get("message")
            expect(messages).to include(message)
            messages.delete(message)
            if message.match /value-[3-4]/
              data.cancel
            end
          end
          received = []
          read_batch.to_a.each do |data|
            received << data.get("message")
          end
          expect(received.size).to eq(3)
          (0..2).each {|i| expect(received).to include("value-#{i}")}
        end

        it "handles Java proxied read-batch object" do
          batch = []
          3.times { |i| batch.push(LogStash::Event.new({"message" => "value-#{i}"})) }
          write_client.push_batch(batch)

          read_batch = read_client.read_batch
          expect { read_client.close_batch(read_batch) }.to_not raise_error
          expect { read_client.close_batch(read_batch.to_java) }.to_not raise_error
        end
      end
    end
  end
end
