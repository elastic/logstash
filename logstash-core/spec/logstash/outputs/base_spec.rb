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

class LogStash::Outputs::NOOPLegacyNoWorkers < ::LogStash::Outputs::Base
  LEGACY_WORKERS_NOT_SUPPORTED_REASON = "legacy reason"

  def register
    workers_not_supported(LEGACY_WORKERS_NOT_SUPPORTED_REASON)
  end
end

describe "LogStash::Outputs::Base#new" do
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
