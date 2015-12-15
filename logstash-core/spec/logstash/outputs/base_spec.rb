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

describe "LogStash::Outputs::Base#new" do
  it "should instantiate cleanly" do
    params = { "dummy_option" => "potatoes", "codec" => "json", "workers" => 2 }
    worker_params = params.dup; worker_params["workers"] = 1

    expect do
      LogStash::Outputs::NOOP.new(params.dup)
    end.not_to raise_error
  end
end
