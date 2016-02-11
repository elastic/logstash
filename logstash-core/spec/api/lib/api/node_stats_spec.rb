# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "app/modules/node_stats"

describe LogStash::Api::NodeStats do

  include Rack::Test::Methods

  def app()
    described_class
  end

  it "respond to the events resource" do
    get "/events"
    expect(last_response).to be_ok
  end

  it "respond to the jvm resource" do
    get "jvm"
    expect(last_response).to be_ok
  end
end
