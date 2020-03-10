# encoding: utf-8
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

      expect{ subject }.not_to raise_error
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

    it "allow to set the context" do
      expect(instance.execution_context).to be_nil
      instance.execution_context = execution_context

      expect(instance.execution_context).to eq(execution_context)
    end

    it "propagate the context to the codec" do
      expect(instance.codec.execution_context).to be_nil
      instance.execution_context = execution_context

      expect(instance.codec.execution_context).to eq(execution_context)
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
