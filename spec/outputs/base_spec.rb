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

describe "LogStash::Outputs::Base#worker_setup" do
  it "should create workers using original parameters except workers = 1" do
    params = { "dummy_option" => "potatoes", "codec" => "json", "workers" => 2 }
    worker_params = params.dup; worker_params["workers"] = 1
    output = LogStash::Outputs::NOOP.new(params.dup)
    expect(LogStash::Outputs::NOOP).to receive(:new).twice.with(worker_params).and_call_original
    output.worker_setup
  end
end
