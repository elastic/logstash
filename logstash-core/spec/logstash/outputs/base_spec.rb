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
require "logstash/outputs/base"
require "support/shared_contexts"

# use a dummy NOOP output to test Outputs::Base
class LogStash::Outputs::NOOPSingle < LogStash::Outputs::Base
  config_name "noop"
  concurrency :single

  config :dummy_option, :validate => :string

  def register; end

  def receive(event)
    return output?(event)
  end
end

class LogStash::Outputs::NOOPShared < ::LogStash::Outputs::Base
  concurrency :shared

  def register; end
end

class LogStash::Outputs::NOOPLegacy < ::LogStash::Outputs::Base
  def register; end
end

class LogStash::Outputs::NOOPMultiReceiveEncoded < ::LogStash::Outputs::Base
  concurrency :single

  def register; end

  def multi_receive_encoded(events_and_encoded)
  end
end

describe "LogStash::Outputs::Base#new" do
  let(:params) { {} }
  subject(:instance) { klass.new(params.dup) }

  context "single" do
    let(:klass) { LogStash::Outputs::NOOPSingle }

    it "should instantiate cleanly" do
      params = { "dummy_option" => "potatoes", "codec" => "json", "workers" => 2 }
      worker_params = params.dup; worker_params["workers"] = 1

      expect { subject }.not_to raise_error
    end

    it "should set concurrency correctly" do
      expect(subject.concurrency).to eq(:single)
    end
  end

  context "shared" do
    let(:klass) { LogStash::Outputs::NOOPShared }

    it "should set concurrency correctly" do
      expect(subject.concurrency).to eq(:shared)
    end
  end

  context "legacy" do
    let(:klass) { LogStash::Outputs::NOOPLegacy }

    it "should set concurrency correctly" do
      expect(subject.concurrency).to eq(:legacy)
    end

    it "should default the # of workers to 1" do
      expect(subject.workers).to eq(1)
    end

    it "should default concurrency to :legacy" do
      expect(subject.concurrency).to eq(:legacy)
    end
  end

  context "execution context" do
    include_context "execution_context"

    let(:klass) { LogStash::Outputs::NOOPSingle }

    subject(:instance) { klass.new(params.dup) }

    context 'execution_context=' do
      let(:deprecation_logger_stub) { double('DeprecationLogger').as_null_object }
      before(:each) do
        allow(klass).to receive(:deprecation_logger).and_return(deprecation_logger_stub)
      end

      it "allow to set the context" do
        new_ctx = execution_context.dup
        subject.execution_context = new_ctx
        expect(subject.execution_context).to be(new_ctx)
      end

      it "propagate the context to the codec" do
        new_ctx = execution_context.dup
        expect(instance.codec.execution_context).to_not be(new_ctx)
        instance.execution_context = new_ctx

        expect(instance.execution_context).to be(new_ctx)
        expect(instance.codec.execution_context).to be(new_ctx)
      end

      it 'emits a deprecation warning' do
        expect(deprecation_logger_stub).to receive(:deprecated) do |message|
          expect(message).to match(/execution_context=/)
        end

        instance.execution_context = execution_context
      end
    end
  end

  describe "dispatching multi_receive" do
    let(:event) { double("event") }
    let(:events) { [event] }

    context "with multi_receive_encoded" do
      let(:klass) { LogStash::Outputs::NOOPMultiReceiveEncoded }
      let(:codec) { double("codec") }
      let(:encoded) { double("encoded") }

      before do
        allow(codec).to receive(:multi_encode).with(events).and_return(encoded)
        allow(instance).to receive(:codec).and_return(codec)
        allow(instance).to receive(:multi_receive_encoded)
        instance.multi_receive(events)
      end

      it "should invoke multi_receive_encoded if it exists" do
        expect(instance).to have_received(:multi_receive_encoded).with(encoded)
      end
    end

    context "with plain #receive" do
      let(:klass) { LogStash::Outputs::NOOPSingle }

      before do
        allow(instance).to receive(:multi_receive).and_call_original
        allow(instance).to receive(:receive).with(event)
        instance.multi_receive(events)
      end

      it "should receive the event by itself" do
        expect(instance).to have_received(:receive).with(event)
      end
    end
  end
end
