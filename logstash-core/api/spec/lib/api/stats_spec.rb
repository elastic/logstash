# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "app/stats"

describe LogStash::Api::Stats do

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

    it "respond to the hot_threads resource" do
      get "#{type}/hot_threads"
      expect(last_response).to be_ok
    end

    it "respond to the memory resource" do
      get "#{type}/memory"
      expect(last_response).to be_ok
    end

  end

end
