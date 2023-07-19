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

require 'spec_helper'

describe ::LogStash::Plugins::Builtin::Pipeline do
  let(:address) {  "fooAdr" }
  let(:input_options) { { "address" => address }}
  let(:output_options) { { "send_to" => [address] }}

  let(:execution_context) { double("execution_context")}
  let(:agent) { double("agent") }
  let(:pipeline_bus) { org.logstash.plugins.pipeline.PipelineBus.new }

  let(:queue) { Queue.new }

  let(:input) { ::LogStash::Plugins::Builtin::Pipeline::Input.new(input_options) }
  let(:output) { ::LogStash::Plugins::Builtin::Pipeline::Output.new(output_options) }
  let(:inputs) { [input] }
  let(:metric) {
    LogStash::Instrument::NamespacedMetric.new(
        LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new), [:filter]
    )
  }

  let(:event) { ::LogStash::Event.new("foo" => "bar") }

  before(:each) do
    allow(execution_context).to receive(:agent).and_return(agent)
    allow(agent).to receive(:pipeline_bus).and_return(pipeline_bus)
    inputs.each do |i|
      allow(i).to receive(:execution_context).and_return(execution_context)
      i.metric = metric
    end
    allow(output).to receive(:execution_context).and_return(execution_context)
    output.metric = metric
  end

  def wait_input_running(input_plugin)
    until input_plugin.running?
      sleep 0.1
    end
  end

  describe "Input/output pair" do
    def start_input
      input.register

      @input_thread = Thread.new do
        input.run(queue)
      end

      wait_input_running(input)
    end

    def stop_input
      input.do_stop
      input.do_close
      @input_thread.join
    end

    context "with both initially running" do
      before(:each) do
        start_input
        output.register
      end

      describe "#internalReceive" do
        it "should fail" do
          java_import "org.logstash.plugins.pipeline.PipelineInput"
          res = input.internalReceive(java.util.ArrayList.new([event]).stream)
          expect(res.status).to eq PipelineInput::ReceiveStatus::COMPLETED
        end
      end

      describe "sending a message" do
        before(:each) do
          output.multi_receive([event])
        end

        subject { queue.pop(true) }

        it "should not send an object with the same identity, but rather, a clone" do
          expect(subject).not_to equal(event)
        end

        it "should send a clone with the correct data" do
          expect(subject.to_hash_with_metadata).to match(event.to_hash_with_metadata)
        end

        # A clone wouldn't be affected here
        it "should no longer have the same content if the original event was modified" do
          event.set("baz", "bot")
          expect(subject.to_hash_with_metadata).not_to match(event.to_hash_with_metadata)
        end

        it 'should add `address` to the plugin metrics' do
          event_metrics = input.metric.collector.snapshot_metric.metric_store.get_with_path(
              "filter"
          )[:filter]
          expect(event_metrics[:address].value).to eq(address)
        end
        it 'should add `send_to` to the plugin metrics' do
          event_metrics = output.metric.collector.snapshot_metric.metric_store.get_with_path(
              "filter"
          )[:filter]
          expect(event_metrics[:send_to].value).to eq([address])
        end
      end

      after(:each) do
        stop_input
        output.do_close
      end
    end

    context "with the input initially stopped" do
      before(:each) do
        output.register
        @receive_thread = Thread.new { output.multi_receive([event]) }
      end

      it "should deliver the message once the input comes up" do
        sleep 3
        start_input
        @receive_thread.join
        expect(queue.pop(true).to_hash_with_metadata).to match(event.to_hash_with_metadata)
      end

      after(:each) do
        stop_input
        output.do_close
      end
    end

    it "stopped input should process events until upstream outputs stop" do
      start_input
      output.register
      pipeline_bus.setBlockOnUnlisten(true)

      output.multi_receive([event])
      expect(queue.pop(true).to_hash_with_metadata).to match(event.to_hash_with_metadata)

      Thread.new { input.do_stop }

      sleep 1
      output.multi_receive([event])
      expect(queue.pop(true).to_hash_with_metadata).to match(event.to_hash_with_metadata)

      output.do_close
    end
  end

  describe "one output to multiple inputs" do
    describe "with all plugins up" do
      let(:other_address) { "other" }
      let(:send_addresses) { [address, other_address]}
      let(:other_input_options) { { "address" => other_address } }
      let(:other_input) { ::LogStash::Plugins::Builtin::Pipeline::Input.new(other_input_options) }
      let(:output_options) { { "send_to" => send_addresses } }
      let(:inputs) { [input, other_input] }
      let(:queues) { [Queue.new, Queue.new] }
      let(:inputs_queues) { Hash[inputs.zip(queues)] }

      before(:each) do
        input.register
        other_input.register
        output.register

        @input_threads = inputs_queues.map do |input_plugin, input_queue|
          Thread.new do
            input_plugin.run(input_queue)
          end
        end
        inputs_queues.each do |input_plugin, input_queue|
          wait_input_running(input_plugin)
        end
      end

      it 'should add multiple `send_to` addresses to the plugin metrics' do
        event_metrics = output.metric.collector.snapshot_metric.metric_store.get_with_path(
            "filter"
        )[:filter]
        expect(event_metrics[:send_to].value).to eq(send_addresses)
      end

      describe "sending a message" do
        before(:each) do
          output.multi_receive([event])
        end

        it "should send the message to both outputs" do
          inputs_queues.each do |i, q|
            expect(q.pop(true).to_hash_with_metadata).to match(event.to_hash_with_metadata)
          end
        end
      end

      context "with ensure delivery set to false" do
        let(:output_options) { super().merge("ensure_delivery" => false) }
        before(:each) do
          other_input.do_stop
          other_input.do_close

          output.multi_receive([event])
        end

        it "should not send the event to the input that is down" do
          expect(inputs_queues[input].pop(true).to_hash_with_metadata).to match(event.to_hash_with_metadata)
          expect(inputs_queues[other_input].size).to eql(0)
        end

        # Test that the function isn't  blocked on the last message
        # a bug could conceivable cause this to hang
        it "should not block subsequent sends" do
          output.multi_receive([event])
          expect(inputs_queues[input].pop(true).to_hash_with_metadata).to match(event.to_hash_with_metadata)
          expect(inputs_queues[input].pop(true).to_hash_with_metadata).to match(event.to_hash_with_metadata)
          expect(inputs_queues[other_input].size).to eql(0)
        end
      end

      after(:each) do
        inputs.each(&:do_stop)
        inputs.each(&:do_close)
        output.do_close
        @input_threads.each(&:join)
      end
    end
  end
end
