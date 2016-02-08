# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "app/modules/node_stats"

describe LogStash::Api::NodeStats do

  include Rack::Test::Methods

  def app()
    described_class
  end

  let(:mem) do
    { :heap_used_in_bytes => 10,
      :pools => { :used_in_bytes => 20 }}
  end

  let(:events) do
    { :in => 10, :out => 20 }
  end

  it "respond to the events resource" do
    expect_any_instance_of(LogStash::Api::StatsEventsCommand).to receive(:run).and_return(events)
    get "/events"
    expect(last_response).to be_ok
  end

  it "respond to the jvm resource" do
    expect_any_instance_of(LogStash::Api::JvmMemoryCommand).to receive(:run).and_return(mem)
    get "jvm"
    expect(last_response).to be_ok
  end
end
