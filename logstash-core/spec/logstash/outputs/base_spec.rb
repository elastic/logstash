# encoding: utf-8
require "spec_helper"

# use a dummy NOOP output to test Outputs::Base
class LogStash::Outputs::NOOP < LogStash::Outputs::Base
  config_name "noop"
  milestone 2

  config :dummy_option, :validate => :string

  def register; end

  def receive(event)
    return output?(event)
  end
end


# use a dummy NOOP output to test Outputs::Base
class LogStash::Outputs::NOOPSingle < LogStash::Outputs::Base
  config_name "noop single"
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

class LogStash::Outputs::NOOPLegacyNoWorkers < ::LogStash::Outputs::Base
  LEGACY_WORKERS_NOT_SUPPORTED_REASON = "legacy reason"

  def register
    workers_not_supported(LEGACY_WORKERS_NOT_SUPPORTED_REASON)
  end
end

describe "LogStash::Outputs::Base#new" do
  describe "concurrency" do
    subject { klass.new({}) }
    
    context "single" do   
      let(:klass) { LogStash::Outputs::NOOPSingle }

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
  end
  
  it "should instantiate cleanly" do
    params = { "dummy_option" => "potatoes", "codec" => "json", "workers" => 2 }
    worker_params = params.dup; worker_params["workers"] = 1

    expect do
      LogStash::Outputs::NOOP.new(params.dup)
    end.not_to raise_error
  end

  it "should move workers_not_supported declarations up to the class level" do
    LogStash::Outputs::NOOPLegacyNoWorkers.new.register
    expect(LogStash::Outputs::NOOPLegacyNoWorkers.workers_not_supported?).to eql(true)
  end
end
