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

  context "jvm" do
    let(:type) { "jvm" }

    it "respond to the memory resource" do
      get "jvm/memory"
      expect(last_response).to be_ok
    end

  end

end
