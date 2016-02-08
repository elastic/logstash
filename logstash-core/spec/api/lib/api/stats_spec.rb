# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "app/modules/stats"

describe LogStash::Api::Stats do

  include Rack::Test::Methods

  def app()
    described_class
  end

  let(:mem) do
    { :heap_used_in_bytes => 10,
      :pools => { :used_in_bytes => 20 }}
  end

  before(:each) do
    expect_any_instance_of(LogStash::Api::JvmMemoryCommand).to receive(:started_at).and_return(1234567890)
    expect_any_instance_of(LogStash::Api::JvmMemoryCommand).to receive(:uptime).and_return(10)
    expect_any_instance_of(LogStash::Api::JvmMemoryCommand).to receive(:run).and_return(mem)
  end

  it "respond to the jvm resource" do
    get "/jvm"
    expect(last_response).to be_ok
  end

end
