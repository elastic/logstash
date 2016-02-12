# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "app/modules/node_stats"

describe LogStash::Api::NodeStats do

  include Rack::Test::Methods

  def app()
    described_class
  end

  context "#root" do

    before(:all) do
      get "/"
    end

    let(:payload) { JSON.parse(last_response.body) }

    it "respond OK" do
      expect(last_response).to be_ok
    end

    ["events", "jvm", "start_time_in_millis"].each do |key|
      it "contains #{key} information" do
        expect(payload).to include(key)
      end
    end
  end

  context "#events" do

    before(:all) do
      get "/events"
    end

    let(:payload) { JSON.parse(last_response.body) }

    it "respond OK" do
      expect(last_response).to be_ok
    end

    it "contains events information" do
      expect(payload).to include("events")
    end
  end

  context "#jvm" do

    before(:all) do
      get "jvm"
    end

    let(:payload) { JSON.parse(last_response.body) }

    it "respond OK" do
      expect(last_response).to be_ok
    end

    it "contains memory information" do
      expect(payload).to include("memory")
    end
  end

end
