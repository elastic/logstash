# encoding: utf-8
require "spec_helper"

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
end
